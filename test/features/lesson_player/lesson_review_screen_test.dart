import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'shows the recorded read-only result for an attempted activity, and a '
    '"not answered" placeholder for one with no attempt at all',
    (tester) async {
      // The review body is a lazy ListView — the default 800x600 test
      // surface only builds the activities that fit on screen. A tall
      // surface renders every row without needing to scroll a sliver into
      // view first, same technique as
      // test/features/learning_path/presentation/unit_path_view_test.dart.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U0-L1']!;

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
        ],
      );
      addTearDown(container.dispose);
      final learner = await container.read(currentLearnerProvider.future);

      // A1-U0-L1 has 4 activities: A01 (audioChoice, answer
      // "morning-office"), A02/A03 (audioChoice), A04 (speak). Only A01 is
      // answered here (correctly); A02, A03, A04 are left entirely
      // unattempted, so all three should render the "not answered"
      // placeholder — A04 in particular (a speak activity) must not fall
      // back to its live recording UI.
      await container
          .read(activityAttemptRepositoryProvider)
          .recordAttempt(
            learnerId: learner.id,
            activityId: 'A1-U0-L1-A01',
            lessonId: lesson.id,
            sessionType: 'lesson',
            mode: ActivityMode.encounter,
            evidenceSkill: Skill.listening,
            canDoIds: const [],
            rawAnswer: '"morning-office"',
            isCorrect: true,
            score: 1.0,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: LessonReviewScreen(unitId: 'A1-U0', lessonId: lesson.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text(l10n.lessonReviewNotAnswered), findsNWidgets(3));
      expect(find.text(l10n.speakStartRecording), findsNothing);
    },
  );

  testWidgets('tapping "Practice again" navigates to the real lesson player', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final lesson = index.lessonsById['A1-U0-L1']!;

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/lesson-review-test',
      routes: [
        GoRoute(
          path: '/lesson-review-test',
          builder: (_, _) =>
              LessonReviewScreen(unitId: 'A1-U0', lessonId: lesson.id),
        ),
        GoRoute(
          path: '/lesson-player/:unitId/:lessonId',
          builder: (_, _) => const Scaffold(body: Text('LESSON_PLAYER_STUB')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.lessonReviewPracticeAgain));
    await tester.pumpAndSettle();

    expect(find.text('LESSON_PLAYER_STUB'), findsOneWidget);
  });
}
