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
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../speech/fake_speech_services.dart';

/// A full, real pass through A1-U0-L1's 3 `audioChoice` + 1 `speak`
/// activities: A01's answer is [a01Answer] (varied between passes to
/// produce two different results for the same activity across a replay);
/// A02/A03/A04 are always answered correctly so the lesson reliably
/// reaches its final activity regardless of A01's outcome. The three
/// `audioChoice` activities (A01-A03) submit the instant an option is
/// tapped — no separate Check tap; only A04 (`speak`, via its typed
/// fallback) still shows one.
Future<void> _playLessonOnce(WidgetTester tester, String a01Answer) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(a01Answer).last);
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text("You're welcome.").last); // A02
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text('Good morning.').last); // A03
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Thank you.'); // A04
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Check
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next (or finish)
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

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final overrides = [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
        // The real A1-U0-L1 audioChoice activities now auto-play their
        // transcript on mount, which reads the TTS rate/pitch preferences —
        // both backed by sharedPreferencesProvider.
        sharedPreferencesProvider.overrideWithValue(prefs),
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

  testWidgets(
    'invalidating lessonReviewAttemptsProvider after a "Practice again" '
    'replay refreshes data an already-open review screen previously '
    'fetched — proving the invalidation itself takes effect, not just that '
    'a freshly-mounted screen naturally fetches fresh data',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = CourseContentIndex.build(
        CourseBundleParser.parse(
          File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
        ),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // A single container, reused for every pump below — the point of this
      // test is that `lessonReviewAttemptsProvider`'s value on *this one*
      // container changes after a replay, which only happens if
      // `LessonPlayerScreen._handleSubmitted` actually invalidates it (a
      // fresh ProviderScope per pump, as the test above uses, would fetch
      // fresh data regardless of whether invalidation ever fired).
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          // The real A1-U0-L1 audioChoice activities now auto-play their
          // transcript on mount, which reads the TTS rate/pitch
          // preferences — both backed by sharedPreferencesProvider.
          sharedPreferencesProvider.overrideWithValue(prefs),
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

      Future<void> pump(Widget home) => tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
          ),
        ),
      );

      // Same tall-viewport technique as the test above — the review body's
      // ListView only builds what fits on screen at the default test size.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // First pass: A01 answered correctly.
      await pump(
        const LessonPlayerScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
      );
      await _playLessonOnce(tester, 'morning-office');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // Open review on the SAME container — this both proves the first
      // attempt is visible and, crucially, establishes
      // lessonReviewAttemptsProvider's cached value on this container (the
      // exact value that must later be invalidated, not just re-fetched
      // fresh).
      await pump(const SizedBox.shrink());
      await pump(
        const LessonReviewScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
      expect(find.byIcon(Icons.cancel), findsNothing);

      // Replay through the SAME container via "Practice again"'s real
      // destination screen: A01 answered incorrectly this time.
      await pump(const SizedBox.shrink());
      await pump(
        const LessonPlayerScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
      );
      await _playLessonOnce(tester, 'night-bedroom');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // `_handleSubmitted` invalidates `lessonReviewAttemptsProvider` on
      // this container for every one of the 4 activities just replayed, but
      // it's a non-autoDispose provider with no active watcher right now
      // (the review screen isn't mounted) — invalidation only actually
      // re-runs the query the next time something reads it. Reading its
      // `.future` here waits for that pending re-fetch to resolve, the same
      // way real navigation (page-transition frames, the learner tapping
      // back into the lesson row) gives it time to settle before a fresh
      // `LessonReviewScreen` ever watches it.
      final learner = await container.read(currentLearnerProvider.future);
      await container.read(
        lessonReviewAttemptsProvider((
          learnerId: learner.id,
          lessonId: 'A1-U0-L1',
        )).future,
      );

      // Re-open review on the SAME container: must reflect the *second*
      // attempt now, not the value already cached from the first pump
      // above. This is the assertion that actually exercises the fix —
      // without `_handleSubmitted`'s `ref.invalidate(
      // lessonReviewAttemptsProvider(...))`, this container would keep
      // serving the stale first-pass data forever.
      await pump(const SizedBox.shrink());
      await pump(
        const LessonReviewScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    },
  );
}
