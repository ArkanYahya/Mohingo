import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/features/activity_engine/presentation/views/gap_activity_view.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';

import 'fake_sound_effects_service.dart';
import 'test_harness.dart';

GapActivity _gapActivity() {
  return const GapActivity(
    id: 'A1-U2-L2-A02',
    lessonId: 'A1-U2-L2',
    mode: ActivityMode.practice,
    skill: Skill.reading,
    canDo: ['A1.U2.PRODUCTION.DESCRIBE_FAMILY'],
    prompt: 'Complete the sentence.',
    promptAr: 'أكمل الجملة.',
    raw: {},
    text: 'She ___ one sister.',
    options: ['have', 'has', 'is'],
    answer: 'has',
  );
}

void main() {
  testWidgets('shows the gapped sentence and every option', (tester) async {
    await tester.pumpActivityView(
      GapActivityView(activity: _gapActivity(), onSubmitted: (_) {}),
    );

    expect(find.textContaining('___'), findsOneWidget);
    for (final option in ['have', 'has', 'is']) {
      expect(find.widgetWithText(ChoiceChip, option), findsOneWidget);
    }
  });

  testWidgets('selecting an option fills the gap in the preview', (
    tester,
  ) async {
    await tester.pumpActivityView(
      GapActivityView(activity: _gapActivity(), onSubmitted: (_) {}),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'has'));
    await tester.pump();

    expect(find.text('She has one sister.'), findsOneWidget);
  });

  testWidgets(
    'choosing an option submits immediately — no separate Check tap needed',
    (tester) async {
      ActivitySubmission? reported;
      await tester.pumpActivityView(
        GapActivityView(
          activity: _gapActivity(),
          onSubmitted: (s) => reported = s,
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'has'));
      await tester.pump();

      expect(reported?.correctness, ActivityCorrectness.correct);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('plays the correct/incorrect sound on submit, never in review '
      'mode', (tester) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      GapActivityView(activity: _gapActivity(), onSubmitted: (_) {}),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'have')); // wrong
    await tester.pump();

    expect(fakeSound.played, [ActivityFeedbackSound.incorrect]);
  });

  testWidgets(
    'renders options in a shuffled order, not the bundle\'s raw JSON order',
    (tester) async {
      const activity = GapActivity(
        id: 'A1-TEST-A02',
        lessonId: 'A1-TEST-L1',
        mode: ActivityMode.practice,
        skill: Skill.reading,
        canDo: [],
        prompt: 'Complete the sentence.',
        promptAr: 'أكمل الجملة.',
        raw: {},
        text: 'Pick ___.',
        options: ['v', 'w', 'x', 'y', 'z'],
        answer: 'v',
      );

      await tester.pumpActivityView(
        GapActivityView(
          activity: activity,
          onSubmitted: (_) {},
          random: Random(0),
        ),
      );

      // Random(0).shuffle() on ['v','w','x','y','z'] deterministically
      // produces ['z','x','y','w','v']. Sorted by (row, then column) since
      // these chips flow left-to-right within a Wrap — several can share
      // the same vertical position, so dy alone can't recover list order.
      Offset topLeft(String option) =>
          tester.getTopLeft(find.widgetWithText(ChoiceChip, option));
      final sortedByPosition =
          [
            for (final option in ['v', 'w', 'x', 'y', 'z']) option,
          ]..sort((a, b) {
            final byRow = topLeft(a).dy.compareTo(topLeft(b).dy);
            return byRow != 0 ? byRow : topLeft(a).dx.compareTo(topLeft(b).dx);
          });

      expect(sortedByPosition, ['z', 'x', 'y', 'w', 'v']);
      expect(
        sortedByPosition,
        isNot(['v', 'w', 'x', 'y', 'z']),
        reason: 'must not render in the original, guessable bundle order',
      );
    },
  );

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no submit button, gap filled from the record',
      (tester) async {
        await tester.pumpActivityView(
          GapActivityView(
            activity: _gapActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L2-A02',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode('has'), // the actually-correct answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.text('She has one sister.'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );

    testWidgets('a never-graded (isCorrect: null) attempt renders the neutral '
        '"saved for review" treatment, never as incorrect', (tester) async {
      await tester.pumpActivityView(
        GapActivityView(
          activity: _gapActivity(),
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'attempt-1',
            learnerId: 1,
            activityId: 'A1-U2-L2-A02',
            sessionType: 'lesson',
            mode: 'practice',
            evidenceSkill: 'reading',
            rawAnswer: jsonEncode('has'),
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
