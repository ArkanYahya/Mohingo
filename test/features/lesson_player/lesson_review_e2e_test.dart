import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../speech/fake_speech_services.dart';

/// A full, real pass through A1-U0-L1's 3 `audioChoice` + 1 `speak`
/// activities: A01's answer is [a01Answer] (varied between passes to
/// produce two different results for the same activity across a replay);
/// A02/A03/A04 are always answered correctly so the lesson reliably
/// reaches its final activity regardless of A01's outcome.
Future<void> _playLessonOnce(WidgetTester tester, String a01Answer) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(a01Answer).last);
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Check
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text("You're welcome.").last); // A02
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text('Good morning.').last); // A03
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Thank you.'); // A04
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'reopening a lesson replayed with a different answer shows the latest '
    '(second) attempt in review, not the first',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = CourseContentIndex.build(
        CourseBundleParser.parse(
          File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
        ),
      );

      final overrides = [
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
      ];

      // First pass: A01 answered correctly.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await _playLessonOnce(tester, 'morning-office');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // Real navigation back into the lesson player (e.g. "Practice again",
      // or tapping the lesson node again) always goes through
      // `context.push('/lesson-player/...')` (see app_router.dart), which
      // pushes a brand-new route and thus a brand-new `LessonPlayerScreen`
      // State — its `initState` re-reads progress from the database and, per
      // `lesson_player_resume_test.dart`, correctly restarts a completed
      // lesson from its first activity. Pumping the *same* widget shape
      // again directly (without this intermediate teardown) would instead
      // have Flutter's element tree reuse the existing State, leaving
      // `_currentIndex` sitting at "lesson complete" — a widget-test
      // artifact of `pumpWidget`, not something that can happen via real
      // navigation, so this blank pump stands in for "closing and
      // reopening" the screen.
      await tester.pumpWidget(const SizedBox.shrink());

      // Replay: A01 answered incorrectly this time.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await _playLessonOnce(tester, 'night-bedroom');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      final a01Attempts = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L1-A01'))).get();
      expect(
        a01Attempts,
        hasLength(2),
        reason: 'insert-only — replaying must append, never overwrite',
      );

      // The review body is a lazy ListView — the default 800x600 test
      // surface only builds the activities that fit on screen. A tall
      // surface renders every row without needing to scroll a sliver into
      // view first, same technique as
      // test/features/lesson_player/lesson_review_screen_test.dart.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Open the review screen: A01 must show the *second* (latest,
      // incorrect) attempt, not the first (correct) one.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonReviewScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A01 wrong (latest); A02/A03/A04 correct on both passes.
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    },
  );
}
