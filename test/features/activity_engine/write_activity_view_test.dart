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
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/activity_engine/presentation/views/write_activity_view.dart';

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
}
