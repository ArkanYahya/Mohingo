import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/unit_overview_screen.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../activity_engine/answer_activity.dart';
import '../speech/fake_speech_services.dart';

/// Real A1-U0-L1 content, indexed the same way `courseContentProvider('a1')`
/// indexes it at runtime — `CourseContentIndex.build`, not the raw
/// `CourseBundle` — matching `lesson_player_e2e_test.dart`'s helper.
CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows a correct/total tally and a next-lesson CTA on lesson '
      'completion, since A1-U0-L1 is not the unit\'s last lesson', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final lesson = index.lessonsById['A1-U0-L1']!;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          textToSpeechServiceProvider.overrideWithValue(
            FakeTextToSpeechService(),
          ),
          // Forces the `speak` activity straight to its typed fallback —
          // no real platform to answer a capability/permission check in
          // this environment. See docs/TESTING.md.
          speechCapabilityServiceProvider.overrideWithValue(
            FakeSpeechCapabilityService(
              const DeviceSpeechCapabilities(
                sttAvailableForLocale: false,
                micPermission: SpeechPermissionStatus.notDetermined,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LessonPlayerScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final activity in lesson.activities) {
      await answerCheckAndAdvance(tester, activity);
    }
    await tester.pumpAndSettle();

    // Reached the lesson-complete screen.
    expect(find.byIcon(Icons.celebration), findsOneWidget);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;

    // Every activity in A1-U0-L1 was answered with its real answer key,
    // so all 4 (3 audioChoice + 1 speak with a non-empty `accepted` list)
    // are auto-graded correct: a 4-of-4 tally, no pending-review line.
    expect(find.text(l10n.lessonCompleteTally(4, 4)), findsOneWidget);
    expect(find.textContaining('saved for review'), findsNothing);

    // A1-U0 has 5 lessons — A1-U0-L1 is not the last, so the forward CTA
    // reads "Next lesson", not "Back to unit".
    expect(find.text(l10n.lessonCompleteNextLesson), findsOneWidget);
    expect(find.text(l10n.lessonCompleteBackToUnit), findsNothing);
  });

  testWidgets(
    'answering one activity without finishing the lesson still marks it '
    'in progress on the unit overview',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U0-L1']!;
      // A1-U0-L1 has 4 activities — answering just the first leaves it
      // unfinished, the case _next()'s finish branch never sees.
      expect(lesson.activities.length, greaterThan(1));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          textToSpeechServiceProvider.overrideWithValue(
            FakeTextToSpeechService(),
          ),
          speechCapabilityServiceProvider.overrideWithValue(
            FakeSpeechCapabilityService(
              const DeviceSpeechCapabilities(
                sttAvailableForLocale: false,
                micPermission: SpeechPermissionStatus.notDetermined,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lessonRow = index.unitsById['A1-U0']!.lessons.indexWhere(
        (l) => l.id == 'A1-U0-L1',
      );
      StatusIndicator lessonIndicator() => tester
          .widgetList<StatusIndicator>(find.byType(StatusIndicator))
          .elementAt(lessonRow);

      // Pump the unit overview FIRST, so `lessonProgressForUnitProvider`
      // gets watched and cached with the "not started" baseline — this is
      // the step that makes the provider non-autoDispose-cached, which is
      // exactly the condition under which stale data would survive if
      // _handleSubmitted didn't invalidate it.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const UnitOverviewScreen(unitId: 'A1-U0'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(lessonIndicator().state, ProgressState.notStarted);

      // Same container, switch to the lesson player and answer only the
      // first activity — the lesson stays unfinished.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await answerCheckAndAdvance(tester, lesson.activities.first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsNothing);

      // Same container again, back to the unit overview — simulating a
      // back-navigation without ever reaching LessonPlayerScreen's _next()
      // finish branch. If _handleSubmitted hadn't invalidated the cached
      // provider, this would still show notStarted.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const UnitOverviewScreen(unitId: 'A1-U0'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(lessonIndicator().state, ProgressState.inProgress);
    },
  );
}
