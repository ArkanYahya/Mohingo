import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../activity_engine/fake_connectivity_service.dart';
import '../activity_engine/fake_grammar_check_service.dart';
import '../speech/fake_speech_services.dart';

/// A full, offline, end-to-end pass through **real** A1-U0-L1 content —
/// the actual copied bundle asset, not a fixture — driven entirely through
/// real widget interaction (tap options, type text, tap Check/Next), the
/// same code path a learner uses. No network call is made or possible: v1
/// has none to make, so "airplane mode" per docs/TESTING.md is trivially
/// satisfied by the architecture itself, not something this test needs to
/// simulate separately.
///
/// Scoped to one lesson rather than the whole 5-lesson A1-U0 unit — driving
/// every activity type across every lesson generically was disproportionate
/// for this pass; this still exercises every layer end to end (parsing,
/// indexing, the activity registry, attempt recording, lesson-position
/// resume bookkeeping, and mastery-aggregation wiring) against real content.
CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

/// Answers [activity] the way a learner would, then taps Next (and, for the
/// activity types that still require one, Check first) — using each
/// activity's own real answer key, since (unlike a learner) the test driver
/// is allowed to know it.
Future<void> _answerAndAdvance(WidgetTester tester, Activity activity) async {
  // Some activity views (e.g. SpeakActivityView) do an async capability
  // check in initState before their real body renders — settle that first.
  await tester.pumpAndSettle();

  // Choice/Gap/Order/Match submit the instant a complete answer is given —
  // no separate Check tap. Speak/Write/Form/Dialogue still show one.
  var needsExplicitCheck = true;

  switch (activity) {
    case AudioChoiceActivity a:
      // `.last`: some answers coincide with their own audioTranscript text
      // (e.g. A1-U0-L1-A03's answer and transcript are both "Good
      // morning."), which renders twice — the transcript help card first,
      // the tappable option second, in that tree order.
      await tester.tap(find.text(a.answer).last);
      needsExplicitCheck = false;
    case TextChoiceActivity a:
      await tester.tap(find.text(a.answer).last);
      needsExplicitCheck = false;
    case GapActivity a:
      // `.first`: a gap activity's own distractor options can coincidentally
      // repeat the same word twice (a real content quirk, not a bug in this
      // test) — either duplicate chip represents the same choice.
      await tester.tap(find.widgetWithText(ChoiceChip, a.answer).first);
      needsExplicitCheck = false;
    case OrderActivity a:
      for (final token in a.answer) {
        await tester.tap(find.text(token).first);
        await tester.pump();
      }
      needsExplicitCheck = false;
    case MatchActivity a:
      // `.first`: a match activity's left/right option pool can
      // coincidentally repeat the same word — either duplicate resolves the
      // pair the same way.
      for (final pair in a.pairs) {
        await tester.tap(find.text(pair[0]).first);
        await tester.pump();
        await tester.tap(find.text(pair[1]).first);
        await tester.pump();
      }
      needsExplicitCheck = false;
    case SpeakActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case WriteActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case FormActivity a:
      final fields = find.byType(TextField);
      for (var i = 0; i < a.fields.length; i++) {
        await tester.enterText(fields.at(i), 'an answer');
      }
    case DialogueActivity _:
      break; // no input required
  }
  await tester.pump();

  if (needsExplicitCheck) {
    await tester.tap(find.byType(FilledButton)); // Check
    await tester.pump();
  }
  await tester.tap(find.byType(FilledButton)); // Next (or finish)
  await tester.pump();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'completing real A1-U0-L1 end to end records every attempt exactly '
    'once, correctly isolates the speaking-fallback evidence, and reaches '
    'the lesson-complete screen having refreshed unit progress',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U0-L1']!;
      expect(
        lesson.activities,
        hasLength(4),
        reason:
            'this test is written against the real content shape — if '
            'A1-U0-L1 changes, update the assertions here alongside it',
      );

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
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final activity in lesson.activities) {
        await _answerAndAdvance(tester, activity);
      }
      await tester.pumpAndSettle();

      // Reached the lesson-complete screen.
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // Every activity recorded exactly once — insert-only, no duplicates,
      // nothing lost.
      final attempts = await db.select(db.activityAttempts).get();
      expect(attempts.map((a) => a.activityId).toSet(), {
        'A1-U0-L1-A01',
        'A1-U0-L1-A02',
        'A1-U0-L1-A03',
        'A1-U0-L1-A04',
      });
      expect(attempts, hasLength(4));

      // A1-U0-L1-A04 is a `speak` activity answered via its typed
      // fallback — must record as writing evidence, never speaking.
      final speakAttempt = attempts.firstWhere(
        (a) => a.activityId == 'A1-U0-L1-A04',
      );
      expect(speakAttempt.wasFallback, isTrue);
      expect(speakAttempt.evidenceSkill, 'writing');

      // The lesson-player's final-activity handler called
      // MasteryAggregationService.refreshUnitProgress for A1-U0 — a
      // unit_progress row now exists reflecting real evidence (not
      // necessarily "mastered" from a single lesson out of five).
      final unitProgress = await (db.select(
        db.unitProgress,
      )..where((t) => t.unitId.equals('A1-U0'))).getSingleOrNull();
      expect(unitProgress, isNotNull);
      expect(
        unitProgress!.state,
        anyOf('notStarted', 'inProgress', 'mastered'),
      );

      // Finishing the lesson recorded exactly one "lesson" daily-task
      // event — feeds Home's "Finish a lesson" task.
      final dailyTaskEvents = await db.select(db.dailyTaskEvents).get();
      expect(
        dailyTaskEvents.where((e) => e.taskType == 'lesson'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'answering an activity incorrectly during live play shows a modal '
    "bottom sheet with the correct answer, not the inline banner — and "
    "its Continue button both dismisses the sheet and advances to the "
    'next activity',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
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
            locale: const Locale('en'),
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

      // A01, A02 — answer correctly with the shared helper.
      await _answerAndAdvance(tester, lesson.activities[0]);
      await _answerAndAdvance(tester, lesson.activities[1]);
      await tester.pumpAndSettle();

      // A03 ("What is the natural reply?", answer "Good morning.") —
      // answer WRONG.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LessonPlayerScreen)),
      )!;
      expect(find.text('Thank you.'), findsOneWidget);
      await tester.tap(find.text('Thank you.'));
      await tester.pumpAndSettle();

      // The bottom sheet is showing, the inline banner/Next button are not.
      expect(find.text(l10n.activityIncorrectSheetTitle), findsOneWidget);
      expect(
        find.text(l10n.activityIncorrectSheetBody('Good morning.')),
        findsOneWidget,
      );
      expect(find.byType(ActivityFeedbackBanner), findsNothing);
      expect(find.text(l10n.lessonPlayerNext), findsNothing);

      await tester.tap(find.text(l10n.activityIncorrectSheetContinue));
      await tester.pumpAndSettle();

      // Advanced to A04 (speak) — the sheet is gone and the progress
      // header reflects the 4th activity.
      expect(find.text(l10n.activityIncorrectSheetTitle), findsNothing);
      expect(find.text(l10n.lessonPlayerProgress(4, 4)), findsOneWidget);

      await db.close();
    },
  );

  testWidgets(
    'a letterSequence/profileName activity (A1-U0-L3-A04, "Spell your '
    'name.") is graded against the learner\'s saved name',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U0-L3']!;
      expect(
        lesson.activities,
        hasLength(4),
        reason:
            'this test is written against the real content shape — if '
            'A1-U0-L3 changes, update the driving steps below alongside it',
      );
      await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-1',
              name: const Value('Ali'),
              createdAt: DateTime.utc(2026, 9, 7),
            ),
          );

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
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A01, A02, A03 — drive with the file's existing generic helper.
      for (final activity in lesson.activities.take(3)) {
        await _answerAndAdvance(tester, activity);
      }

      // A04 ("Spell your name.") — answer manually to assert on its grading.
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'a l i');
      await tester.pump();
      await tester.tap(find.byType(FilledButton)); // Check
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await db.close();
    },
  );

  testWidgets(
    'an onlineRefinement activity is queued in pending_online_refinements, '
    'not recorded as an ordinary attempt, when submitted',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U5-L6']!;
      final lastActivity = lesson.activities.last;
      expect(
        lastActivity.id,
        'A1-U5-L6-A05',
        reason:
            'this test is written against the real content shape — if '
            'A1-U5-L6 changes, update the assumption here alongside it',
      );

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
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U5',
              lessonId: 'A1-U5-L6',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final activity in lesson.activities.sublist(
        0,
        lesson.activities.length - 1,
      )) {
        await _answerAndAdvance(tester, activity);
      }

      // A1-U5-L6-A05 — a `write` activity with wordGuide [35, 55]; drive it
      // manually, since a wordGuide-shaped answer isn't what
      // _answerAndAdvance's generic "an answer" text produces.
      await tester.enterText(
        find.byType(TextField),
        'Hello! I love hiking and reading on weekends. Would you like to join '
        'me for a walk in the park this Saturday afternoon?',
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final attemptRows = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
      expect(
        attemptRows,
        isEmpty,
        reason:
            'a queued, not-yet-refined answer must not appear as an '
            'ordinary attempt yet',
      );

      final pendingRows = await (db.select(
        db.pendingOnlineRefinements,
      )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
      expect(pendingRows, hasLength(1));
      expect(pendingRows.single.lessonId, 'A1-U5-L6');
      expect(pendingRows.single.unitId, 'A1-U5');
      expect(pendingRows.single.mode, 'mastery');

      await db.close();
    },
  );

  testWidgets(
    'an onlineRefinement activity submitted while already online resolves '
    'promptly — the drainer used to trigger only at app start and on a '
    'connectivity-change event, so a learner who was online the whole '
    'time (no transition, no restart) would see it stuck on "pending" '
    'indefinitely',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U5-L6']!;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Online for the whole test — `setOnline` (the only thing that fires
      // `onlineChanges`) is never called, so the connectivity-regained
      // trigger never fires either.
      final connectivity = FakeConnectivityService(online: true);

      await tester.pumpWidget(
        ProviderScope(
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
            connectivityServiceProvider.overrideWithValue(connectivity),
            grammarCheckServiceProvider.overrideWithValue(
              FakeGrammarCheckService(
                result: const GrammarCheckResult(errorCount: 0, wordCount: 20),
              ),
            ),
          ],
          // Mirrors MohingoApp watching pendingRefinementDrainerProvider at
          // its own root — the app's one and only drainer instance, alive
          // for the app's lifetime, exactly as in the real app.
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(pendingRefinementDrainerProvider);
              return MaterialApp(
                theme: AppTheme.light(AppColorSeed.calmTeal),
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const LessonPlayerScreen(
                  unitId: 'A1-U5',
                  lessonId: 'A1-U5-L6',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final activity in lesson.activities.sublist(
        0,
        lesson.activities.length - 1,
      )) {
        await _answerAndAdvance(tester, activity);
      }

      // A1-U5-L6-A05 — submit the onlineRefinement write activity.
      await tester.enterText(
        find.byType(TextField),
        'Hello! I love hiking and reading on weekends. Would you like to join '
        'me for a walk in the park this Saturday afternoon?',
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton));

      // The post-enqueue drain trigger and its async chain (grammar check,
      // recording the real attempt, removing the queue row) are all
      // fire-and-forget — give the microtask/frame queue time to run them.
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      final pendingRows = await (db.select(
        db.pendingOnlineRefinements,
      )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
      expect(
        pendingRows,
        isEmpty,
        reason:
            'a learner who is online the entire time this test runs must '
            'not be left on "pending" — nothing here ever fires a '
            'connectivity-change event or recreates the provider, so '
            'app-start and connectivity-regained cannot be what resolved '
            'this',
      );

      final attemptRows = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
      expect(attemptRows, hasLength(1));

      await db.close();
    },
  );
}
