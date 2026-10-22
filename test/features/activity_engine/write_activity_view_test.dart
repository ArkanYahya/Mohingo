import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_context.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grading_signals.dart';
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/activity_engine/presentation/views/write_activity_view.dart';
import 'package:riverpod/misc.dart' show Override;

import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';

import 'fake_local_judgement_service.dart';
import 'fake_meaning_signal_service.dart';
import 'fake_sound_effects_service.dart';
import 'test_harness.dart';

WriteActivity _openEndedWrite() {
  return const WriteActivity(
    id: 'A1-U2-L6-A04',
    lessonId: 'A1-U2-L6',
    mode: ActivityMode.mastery,
    skill: Skill.writing,
    canDo: ['A1.U2.WRITING.WRITE_PEOPLE_PROFILE'],
    prompt: 'Write 4-6 short sentences about one person.',
    promptAr: 'اكتب 4-6 جمل قصيرة عن شخص واحد.',
    raw: {},
    accepted: [],
    wordGuide: [25, 45],
  );
}

WriteActivity _closedFormWrite() {
  return const WriteActivity(
    id: 'A1-U6-L1-A04',
    lessonId: 'A1-U6-L1',
    mode: ActivityMode.mastery,
    skill: Skill.writing,
    canDo: ['A1.U6.WRITING.WRITE_SIMPLE_ORDER'],
    prompt: 'Write your order.',
    promptAr: 'اكتب طلبك.',
    raw: {},
    accepted: ['One coffee, please.'],
  );
}

void main() {
  testWidgets('a mediation write shows its source card', (tester) async {
    await tester.pumpActivityView(
      WriteActivityView(
        activity: const WriteActivity(
          id: 'A1-FINAL-ASSESS-M02',
          lessonId: null,
          mode: ActivityMode.mastery,
          skill: Skill.mediation,
          canDo: [],
          prompt: 'Relay the clinic notice.',
          promptAr: 'انقل ملاحظة العيادة.',
          raw: {'sourceCard': 'Clinic B, 2nd floor. Appointment 14:30.'},
          accepted: [],
        ),
        learnerId: 1,
        onSubmitted: (_) {},
      ),
    );

    expect(
      find.text('Clinic B, 2nd floor. Appointment 14:30.'),
      findsOneWidget,
    );
  });

  testWidgets("counts words live against the question's word guide", (
    tester,
  ) async {
    await tester.pumpActivityView(
      WriteActivityView(
        activity: _openEndedWrite(),
        learnerId: 1,
        onSubmitted: (_) {},
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    expect(find.text(l10n.activityWordCount(0)), findsOneWidget);
    expect(find.text(l10n.activityWordGuideTarget(25, 45)), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '  This is my  sister,\nNoor. ',
    );
    await tester.pump();

    expect(find.text(l10n.activityWordCount(5)), findsOneWidget);
  });

  testWidgets('a write with no word guide shows no counter', (tester) async {
    await tester.pumpActivityView(
      WriteActivityView(
        activity: _closedFormWrite(),
        learnerId: 1,
        onSubmitted: (_) {},
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    expect(find.text(l10n.activityWordCount(0)), findsNothing);
  });

  testWidgets('an open-ended write (no accepted list) is notAutoGraded', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      WriteActivityView(
        activity: _openEndedWrite(),
        learnerId: 1,
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.enterText(find.byType(TextField), 'This is my sister.');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.notAutoGraded);
  });

  testWidgets(
    'a closed-form write with an accepted list is auto-graded correct '
    'case-insensitively',
    (tester) async {
      ActivitySubmission? reported;
      await tester.pumpActivityView(
        WriteActivityView(
          activity: _closedFormWrite(),
          learnerId: 1,
          onSubmitted: (s) => reported = s,
        ),
      );

      await tester.enterText(find.byType(TextField), 'one coffee, please.');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(reported?.correctness, ActivityCorrectness.correct);
    },
  );

  testWidgets(
    'plays the correct sound when a closed-form answer grades correct, and '
    'no sound at all for a notAutoGraded (open-ended) submission',
    (tester) async {
      final fakeSound = FakeSoundEffectsService();
      await tester.pumpActivityView(
        WriteActivityView(
          activity: _closedFormWrite(),
          learnerId: 1,
          onSubmitted: (_) {},
        ),
        overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
      );

      await tester.enterText(find.byType(TextField), 'One coffee, please.');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(fakeSound.played, [ActivityFeedbackSound.correct]);
    },
  );

  testWidgets('an open-ended (notAutoGraded) submission never plays a sound', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      WriteActivityView(
        activity: _openEndedWrite(),
        learnerId: 1,
        onSubmitted: (_) {},
      ),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    await tester.enterText(find.byType(TextField), 'This is my sister.');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(fakeSound.played, isEmpty);
  });

  testWidgets(
    'an activity with a structured evaluation spec (no accepted list) is '
    'graded via it, not left notAutoGraded',
    (tester) async {
      const activity = WriteActivity(
        id: 'A1-TEST-A01',
        lessonId: 'A1-TEST-L1',
        mode: ActivityMode.mastery,
        skill: Skill.writing,
        canDo: [],
        prompt: 'Write your name.',
        promptAr: 'اكتب اسمك.',
        raw: {},
        accepted: [],
        evaluation: NonEmptyEvaluationSpec(),
      );

      ActivitySubmission? captured;
      await tester.pumpActivityView(
        WriteActivityView(
          activity: activity,
          learnerId: 1,
          onSubmitted: (s) => captured = s,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();

      expect(captured!.correctness, ActivityCorrectness.correct);
    },
  );

  testWidgets(
    'an incorrect letterSequence answer reveals the resolved reference as '
    'the correct answer, not a blank "the correct answer is:"',
    (tester) async {
      const activity = WriteActivity(
        id: 'A1-U0-L5-A02',
        lessonId: 'A1-U0-L5',
        mode: ActivityMode.mastery,
        skill: Skill.writing,
        canDo: ['A1.U0.PRODUCTION.SPELL_NAME'],
        prompt: 'How do you spell it?',
        promptAr: 'كيف تتهجّاه؟',
        raw: {},
        accepted: [],
        evaluation: LetterSequenceEvaluationSpec(
          reference: ProfileNameReference(),
        ),
      );

      await tester.pumpActivityView(
        WriteActivityView(
          activity: activity,
          learnerId: 1,
          onSubmitted: (_) {},
          evaluationContext: const EvaluationContext(profileName: 'Arkan'),
        ),
      );

      await tester.enterText(find.byType(TextField), 'x y z');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();

      expect(
        find.text('Not quite — the correct answer is: Arkan'),
        findsOneWidget,
      );
    },
  );

  group('onlineRefinement rubric', () {
    const activity = WriteActivity(
      id: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      mode: ActivityMode.mastery,
      skill: Skill.writing,
      canDo: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      prompt: 'Write a message about your free time.',
      promptAr: 'اكتب رسالة عن وقت فراغك.',
      raw: {},
      accepted: [],
      evaluation: KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
        ],
        minGroupsMatched: 1,
        onlineRefinement: 'grammarCheck',
      ),
      wordGuide: [35, 55],
    );

    testWidgets(
      'is queued, not graded, and shows the pending-online-refinement '
      'banner',
      (tester) async {
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
        await tester.pumpActivityView(
          WriteActivityView(
            activity: activity,
            learnerId: learnerId,
            onSubmitted: (s) => captured = s,
          ),
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );

        await tester.enterText(
          find.byType(TextField),
          'Hello! Free on Saturday?',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pump();

        expect(captured!.pendingOnlineRefinement, isTrue);
        expect(captured!.correctness, ActivityCorrectness.notAutoGraded);
        expect(captured!.score, 1.0); // 1/1 required group matched, locally
        expect(
          find.text('Saved — we\'ll finish checking this once you\'re online'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'flips from the pending banner to the real Correct/Incorrect result '
      'the moment a matching resolved attempt appears in the database — '
      'without the learner leaving or re-entering the activity',
      (tester) async {
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

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light(AppColorSeed.calmTeal),
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: WriteActivityView(
                  activity: activity,
                  learnerId: learnerId,
                  onSubmitted: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.enterText(
          find.byType(TextField),
          'Hello! Free on Saturday?',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pump();

        expect(
          find.text('Saved — we\'ll finish checking this once you\'re online'),
          findsOneWidget,
        );

        // Exactly what PendingRefinementDrainService._finalize does once
        // the deferred grammar check comes back — write the real attempt,
        // then (via onItemResolved in production) invalidate
        // latestAttemptProvider. Simulated directly here since no real
        // network call happens in this test.
        await db
            .into(db.activityAttempts)
            .insert(
              ActivityAttemptsCompanion.insert(
                uuid: 'attempt-1',
                learnerId: learnerId,
                activityId: activity.id,
                sessionType: 'lesson',
                mode: activity.mode.name,
                evidenceSkill: activity.skill.name,
                isCorrect: const Value(false),
                score: const Value(0.204),
                attemptedAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        container.invalidate(latestAttemptProvider);
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Saved — we\'ll finish checking this once you\'re online'),
          findsNothing,
          reason: 'the stale pending message must not still be showing',
        );
        expect(find.byIcon(Icons.cancel), findsOneWidget);
      },
    );
  });

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'pre-fills the recorded text, disabled, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no submit button, no online-refinement watch',
      (tester) async {
        await tester.pumpActivityView(
          WriteActivityView(
            activity: _closedFormWrite(),
            learnerId: 1,
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U6-L1-A04',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing',
              rawAnswer: jsonEncode(
                'One coffee, please.',
              ), // the actually-accepted answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, isFalse);
        expect(field.controller!.text, 'One coffee, please.');
      },
    );

    testWidgets('a never-graded (isCorrect: null) attempt renders the neutral '
        '"saved for review" treatment, never as incorrect', (tester) async {
      await tester.pumpActivityView(
        WriteActivityView(
          activity: _closedFormWrite(),
          learnerId: 1,
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'attempt-1',
            learnerId: 1,
            activityId: 'A1-U6-L1-A04',
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'writing',
            rawAnswer: jsonEncode('One coffee, please.'),
            isCorrect: null,
            score: null,
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 9, 9),
            updatedAt: DateTime.utc(2026, 9, 9),
          ),
        ),
      );

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  testWidgets('a write with both a model answer and a rubric is graded by '
      'the rubric; the model answer is what is shown after a miss (ADR '
      '0009)', (tester) async {
    final activity = WriteActivity(
      id: 'A1-U6-L1-A04',
      lessonId: 'A1-U6-L1',
      mode: ActivityMode.mastery,
      skill: Skill.writing,
      canDo: const ['A1.U6.WRITING.WRITE_SIMPLE_ORDER'],
      prompt: 'Write your order.',
      promptAr: 'اكتب طلبك.',
      raw: const {},
      accepted: const ['One coffee, please.'],
      evaluation: EvaluationSpec.fromJson({
        'type': 'keywordChecklist',
        'requiredGroups': [
          ['coffee', 'tea'],
          ['please'],
        ],
        'minGroupsMatched': 2,
      }),
    );

    Future<ActivitySubmission?> submit(String text) async {
      ActivitySubmission? reported;
      await tester.pumpActivityView(
        WriteActivityView(
          // A fresh view per answer: without a key the second pump keeps
          // the first submission's state.
          key: ValueKey(text),
          activity: activity,
          learnerId: 1,
          onSubmitted: (s) => reported = s,
        ),
      );
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      return reported;
    }

    // Not the model answer word for word, but everything the rubric asks.
    expect(
      (await submit('A tea, please.'))?.correctness,
      ActivityCorrectness.correct,
    );
    final missed = await submit('One coffee.');
    expect(missed?.correctness, ActivityCorrectness.incorrect);
    expect(missed?.correctAnswerLabel, 'One coffee, please.');
  });

  group('ADR 0011: the meaning signal', () {
    // A rubric asking for two things, with a model answer; the answer below
    // covers one of them, so the rubric alone scores 0.5 and fails.
    const activity = WriteActivity(
      id: 'A2-U1-L4-A05',
      lessonId: 'A2-U1-L4',
      mode: ActivityMode.mastery,
      skill: Skill.writing,
      canDo: ['A2.U1.WRITING.WRITE_LIFE_UPDATE'],
      prompt: 'Reply to your friend.',
      promptAr: 'ردّ على صديقك.',
      raw: {},
      accepted: ['That sounds great! Do you like it? I enjoy cooking now.'],
      evaluation: KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['sounds great', 'interesting'],
          ['do you', 'are you'],
        ],
        minGroupsMatched: 2,
      ),
    );

    Future<ActivitySubmission?> submit(
      WidgetTester tester, {
      required List<Override> overrides,
      Widget Function(Widget child)? wrap,
    }) async {
      ActivitySubmission? captured;
      final view = WriteActivityView(
        activity: activity,
        learnerId: 1,
        onSubmitted: (s) => captured = s,
      );
      await tester.pumpActivityView(
        wrap == null ? view : wrap(view),
        overrides: overrides,
      );
      await tester.enterText(find.byType(TextField), 'That sounds great!');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();
      await tester.pump();
      return captured;
    }

    testWidgets('without a signal the rubric grades exactly as before', (
      tester,
    ) async {
      final captured = await submit(tester, overrides: const []);
      expect(captured!.correctness, ActivityCorrectness.incorrect);
      expect(captured.score, 0.5);
      expect(captured.criteriaScoresJson, isNull);
    });

    testWidgets('a full meaning match raises a half-covered answer to the '
        'pass bar, and the signals are recorded', (tester) async {
      final meaning = FakeMeaningSignalService(signal: 1.0);
      final captured = await submit(
        tester,
        overrides: [meaningSignalServiceProvider.overrideWithValue(meaning)],
      );
      expect(meaning.calls.single.modelAnswers, activity.accepted);
      expect(captured!.correctness, ActivityCorrectness.correct);
      expect(captured.score, closeTo(0.75, 1e-9));
      final criteria =
          jsonDecode(captured.criteriaScoresJson!) as Map<String, dynamic>;
      expect(criteria['rubric'], 0.5);
      expect(criteria['meaning'], 1.0);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('a weak meaning match cannot rescue the answer', (
      tester,
    ) async {
      final captured = await submit(
        tester,
        overrides: [
          meaningSignalServiceProvider.overrideWithValue(
            FakeMeaningSignalService(signal: 0.3),
          ),
        ],
      );
      expect(captured!.correctness, ActivityCorrectness.incorrect);
      expect(captured.score, closeTo(0.575, 1e-9));
    });

    testWidgets('inside a frame that grades on the rubric alone the signal '
        'is never consulted', (tester) async {
      final meaning = FakeMeaningSignalService(signal: 1.0);
      final captured = await submit(
        tester,
        overrides: [meaningSignalServiceProvider.overrideWithValue(meaning)],
        wrap: (child) => ActivityFrameScope(
          onContinue: () {},
          signalsEnabled: false,
          child: child,
        ),
      );
      expect(meaning.calls, isEmpty);
      expect(captured!.correctness, ActivityCorrectness.incorrect);
      expect(captured.score, 0.5);
    });

    testWidgets('with an AI pack installed the answer is queued for the pack '
        'alone — never allowed online — and says so', (tester) async {
      // A pending submission watches latestAttemptProvider, which reads the
      // database — an in-memory one here, as in the onlineRefinement group.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final captured = await submit(
        tester,
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          meaningSignalServiceProvider.overrideWithValue(
            FakeMeaningSignalService(signal: 0.9),
          ),
          localJudgementServiceProvider.overrideWithValue(
            FakeLocalJudgementService(available: true),
          ),
        ],
      );
      expect(captured!.pendingOnlineRefinement, isTrue);
      expect(captured.onlineRefinementAllowed, isFalse);
      expect(captured.correctness, ActivityCorrectness.notAutoGraded);
      expect(captured.score, 0.5, reason: 'the rubric score, not combined');
      expect(captured.meaningSignal, 0.9);
      expect(find.text('Saved — checking this on your phone'), findsOneWidget);
    });

    testWidgets('review mode shows the stored explanation, labelled as '
        'generated, under the recorded verdict', (tester) async {
      await tester.pumpActivityView(
        WriteActivityView(
          activity: activity,
          learnerId: 1,
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'a-1',
            learnerId: 1,
            activityId: activity.id,
            lessonId: activity.lessonId,
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'writing',
            rawAnswer: jsonEncode('That sounds great!'),
            isCorrect: true,
            score: 0.85,
            criteriaScores: criteriaScoresJson(
              const GradingSignals(rubric: 0.5, meaning: 1, meaningOk: true),
              finalScore: 0.85,
              explanationEn: 'You showed interest. Now ask a question.',
              explanationAr: 'أظهرت اهتمامك. اسأل سؤالاً الآن.',
            ),
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 10, 22),
            updatedAt: DateTime.utc(2026, 10, 22),
          ),
        ),
      );

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('EXPLANATION'), findsOneWidget);
      expect(
        find.text('You showed interest. Now ask a question.'),
        findsOneWidget,
      );
      expect(find.text('أظهرت اهتمامك. اسأل سؤالاً الآن.'), findsOneWidget);
      expect(find.text('Generated on your phone'), findsOneWidget);
    });

    testWidgets('an attempt without an explanation shows no explanation '
        'block', (tester) async {
      await tester.pumpActivityView(
        WriteActivityView(
          activity: activity,
          learnerId: 1,
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'a-1',
            learnerId: 1,
            activityId: activity.id,
            lessonId: activity.lessonId,
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'writing',
            rawAnswer: jsonEncode('That sounds great!'),
            isCorrect: false,
            score: 0.5,
            criteriaScores: null,
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 10, 22),
            updatedAt: DateTime.utc(2026, 10, 22),
          ),
        ),
      );

      expect(find.text('EXPLANATION'), findsNothing);
      expect(find.text('Generated on your phone'), findsNothing);
    });
  });
}
