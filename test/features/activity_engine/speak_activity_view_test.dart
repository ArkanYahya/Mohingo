import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_context.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/presentation/views/speak_activity_view.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
// `Override` isn't part of flutter_riverpod's public export surface (an
// explicit `show` list omits it) — it's only exported from this path.
import 'package:riverpod/misc.dart' show Override;

import '../../features/speech/fake_speech_services.dart';

SpeakActivity _speakActivity() {
  return const SpeakActivity(
    id: 'A1-U0-L1-A04',
    lessonId: 'A1-U0-L1',
    mode: ActivityMode.mastery,
    skill: Skill.spokenInteraction,
    canDo: ['A1.U0.INTERACTION.RESPOND_GREETING'],
    prompt: 'A person helps you. Respond politely.',
    promptAr: 'شخص يساعدك. ردّ بأدب.',
    raw: {},
    accepted: ['Thank you.', 'Thanks.'],
    fallbackSkill: 'writing',
  );
}

Future<void> _pumpSpeak(
  WidgetTester tester, {
  required DeviceSpeechCapabilities capabilities,
  FakeSpeechRecognitionService? recognitionService,
  void Function(ActivitySubmission)? onSubmitted,
  Locale locale = const Locale('en'),
  SpeakActivity? activity,
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
  int learnerId = 1,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speechCapabilityServiceProvider.overrideWithValue(
          FakeSpeechCapabilityService(capabilities),
        ),
        speechRecognitionServiceProvider.overrideWithValue(
          recognitionService ?? FakeSpeechRecognitionService(),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SpeakActivityView(
            activity: activity ?? _speakActivity(),
            learnerId: learnerId,
            onSubmitted: onSubmitted ?? (_) {},
            evaluationContext: evaluationContext,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('capability detection', () {
    testWidgets(
      'when recording is available right now, shows the Record button '
      'directly — never requests permission speculatively',
      (tester) async {
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: true,
            micPermission: SpeechPermissionStatus.granted,
          ),
        );

        expect(find.widgetWithText(FilledButton, 'Record'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'when the locale is supported but permission not yet granted, offers '
      'to enable the microphone rather than the typed fallback directly',
      (tester) async {
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: true,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
        );

        expect(
          find.widgetWithText(FilledButton, 'Enable microphone'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when speech is unavailable on this device, goes straight to the '
      'typed fallback with an explanation',
      (tester) async {
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: false,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.textContaining("isn't available on this device"),
          findsOneWidget,
        );
      },
    );

    testWidgets('when the microphone is permanently denied, goes to the typed '
        'fallback with settings-specific copy, not the generic message', (
      tester,
    ) async {
      await _pumpSpeak(
        tester,
        capabilities: const DeviceSpeechCapabilities(
          sttAvailableForLocale: true,
          micPermission: SpeechPermissionStatus.permanentlyDenied,
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('turned off for this app'), findsOneWidget);
    });
  });

  group('permission-denied -> fallback', () {
    testWidgets(
      'requesting the microphone and having it denied falls back to typed '
      'input, without ever starting recognition',
      (tester) async {
        final recognition = FakeSpeechRecognitionService(
          initialPermission: SpeechPermissionStatus.notDetermined,
          permissionAfterRequest: SpeechPermissionStatus.denied,
        );
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: true,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
          recognitionService: recognition,
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'Enable microphone'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Record'), findsNothing);
      },
    );

    testWidgets('the learner can switch to typed input even when recording is '
        'available, without being forced through the microphone', (
      tester,
    ) async {
      await _pumpSpeak(
        tester,
        capabilities: const DeviceSpeechCapabilities(
          sttAvailableForLocale: true,
          micPermission: SpeechPermissionStatus.granted,
        ),
      );

      await tester.tap(find.text('Type my answer instead'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('no-speaking-evidence-from-fallback', () {
    testWidgets('submitting via the typed fallback sets wasFallback=true', (
      tester,
    ) async {
      ActivitySubmission? reported;
      await _pumpSpeak(
        tester,
        capabilities: const DeviceSpeechCapabilities(
          sttAvailableForLocale: false,
          micPermission: SpeechPermissionStatus.notDetermined,
        ),
        onSubmitted: (s) => reported = s,
      );

      await tester.enterText(find.byType(TextField), 'Thanks.');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(reported?.wasFallback, isTrue);
      expect(reported?.correctness, ActivityCorrectness.correct);
    });

    testWidgets(
      'a typed answer missing the accepted answer\'s terminal punctuation '
      'still grades correct',
      (tester) async {
        ActivitySubmission? reported;
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: false,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
          onSubmitted: (s) => reported = s,
        );

        // Accepted answer is "Thanks." (with a period) — a real learner
        // typing (or a transcript omitting) the bare word must still pass.
        await tester.enterText(find.byType(TextField), 'thanks');
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(reported?.correctness, ActivityCorrectness.correct);
      },
    );

    testWidgets(
      'submitting a real recognized transcript sets wasFallback=false — '
      'genuine speaking evidence, not a fallback',
      (tester) async {
        ActivitySubmission? reported;
        final recognition = FakeSpeechRecognitionService(
          results: const [
            SpeechRecognitionResult(transcript: 'Thank you.', isFinal: true),
          ],
        );
        await _pumpSpeak(
          tester,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: true,
            micPermission: SpeechPermissionStatus.granted,
          ),
          recognitionService: recognition,
          onSubmitted: (s) => reported = s,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Record'));
        await tester.pumpAndSettle();

        // The recognized transcript is shown for review before submission.
        expect(find.text('Thank you.'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pump();

        expect(reported?.wasFallback, isFalse);
        expect(reported?.correctness, ActivityCorrectness.correct);
      },
    );
  });

  group('structured evaluation spec', () {
    testWidgets(
      'an activity with a structured evaluation spec is graded via it '
      'through the typed-fallback path',
      (tester) async {
        const activity = SpeakActivity(
          id: 'A1-U0-L5-A01',
          lessonId: 'A1-U0-L5',
          mode: ActivityMode.mastery,
          skill: Skill.spokenInteraction,
          canDo: ['A1.U0.INTERACTION.REGISTER_FOR_CLASS'],
          prompt: "What's your name?",
          promptAr: 'ما اسمك؟',
          raw: {},
          accepted: [],
          evaluation: NonEmptyEvaluationSpec(),
          fallbackSkill: 'writing',
        );

        ActivitySubmission? captured;
        // This exact capability combination is this file's/the codebase's
        // established way to force a `speak` activity straight to its typed
        // fallback in a widget test, with no real platform to answer a
        // capability/permission check — see
        // test/features/lesson_player/lesson_player_e2e_test.dart.
        await _pumpSpeak(
          tester,
          activity: activity,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: false,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
          onSubmitted: (s) => captured = s,
        );

        await tester.enterText(find.byType(TextField), 'Ali');
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        expect(captured!.correctness, ActivityCorrectness.correct);
        expect(captured!.wasFallback, isTrue);
      },
    );
  });

  group('onlineRefinement queuing', () {
    testWidgets(
      'an activity with an onlineRefinement rubric is queued through the '
      'typed-fallback path, not graded',
      (tester) async {
        const activity = SpeakActivity(
          id: 'A1-U5-L6-A05',
          lessonId: 'A1-U5-L6',
          mode: ActivityMode.mastery,
          skill: Skill.spokenProduction,
          canDo: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
          prompt: 'Tell a friend about your free time.',
          promptAr: 'أخبر صديقاً عن وقت فراغك.',
          raw: {},
          accepted: [],
          evaluation: KeywordChecklistEvaluationSpec(
            requiredGroups: [
              ['hi', 'hello'],
            ],
            minGroupsMatched: 1,
            onlineRefinement: 'grammarCheck',
          ),
          fallbackSkill: 'writing',
        );

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final learnerId = await db
            .into(db.learners)
            .insert(
              LearnersCompanion.insert(
                uuid: 'learner-1',
                createdAt: DateTime.utc(2026, 9, 8),
              ),
            );

        ActivitySubmission? captured;
        await _pumpSpeak(
          tester,
          activity: activity,
          capabilities: const DeviceSpeechCapabilities(
            sttAvailableForLocale: false,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
          onSubmitted: (s) => captured = s,
          learnerId: learnerId,
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );

        await tester.enterText(
          find.byType(TextField),
          'Hello! Free on Saturday?',
        );
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        expect(captured!.pendingOnlineRefinement, isTrue);
        expect(captured!.correctness, ActivityCorrectness.notAutoGraded);
        expect(captured!.wasFallback, isTrue);
      },
    );
  });

  group('letter-spelling accepted answers', () {
    SpeakActivity spellActivity() {
      return const SpeakActivity(
        id: 'A1-U0-L3-A03',
        lessonId: 'A1-U0-L3',
        mode: ActivityMode.practice,
        skill: Skill.spokenProduction,
        canDo: ['A1.U0.PRODUCTION.SPELL_NAME'],
        prompt: 'Spell the name Ali.',
        promptAr: 'تهجّى اسم علي.',
        raw: {},
        accepted: ['A-L-I'],
        fallbackSkill: 'writing',
      );
    }

    testWidgets('a spoken-out-loud spelling ("a l i") grades correct against a '
        'hyphen-joined accepted answer ("A-L-I")', (tester) async {
      ActivitySubmission? reported;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            speechCapabilityServiceProvider.overrideWithValue(
              FakeSpeechCapabilityService(
                const DeviceSpeechCapabilities(
                  sttAvailableForLocale: false,
                  micPermission: SpeechPermissionStatus.notDetermined,
                ),
              ),
            ),
            speechRecognitionServiceProvider.overrideWithValue(
              FakeSpeechRecognitionService(),
            ),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SpeakActivityView(
                activity: spellActivity(),
                learnerId: 1,
                onSubmitted: (s) => reported = s,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a l i');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(reported?.correctness, ActivityCorrectness.correct);
    });
  });
}
