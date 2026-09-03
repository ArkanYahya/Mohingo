import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/dialogue_activity_view.dart';

import 'test_harness.dart';

/// A hand-authored fixture — `dialogue` has zero authored instances in the
/// real A1 bundle (verified this session), so this is the only way to
/// exercise the renderer for this type. See docs/TESTING.md.
DialogueActivity _handAuthoredFixture() {
  return const DialogueActivity(
    id: 'FIXTURE-DIALOGUE-1',
    lessonId: 'FIXTURE-LESSON',
    mode: ActivityMode.practice,
    skill: Skill.spokenInteraction,
    canDo: ['A1.FIXTURE.TEST'],
    prompt: 'Practice this dialogue.',
    promptAr: 'مارس هذا الحوار.',
    raw: {'type': 'dialogue', 'note': 'hand-authored test fixture'},
  );
}

void main() {
  testWidgets('renders without crashing on the hand-authored fixture', (
    tester,
  ) async {
    await tester.pumpActivityView(
      DialogueActivityView(
        activity: _handAuthoredFixture(),
        onSubmitted: (_) {},
      ),
    );

    expect(find.text('Practice this dialogue.'), findsOneWidget);
  });

  testWidgets('acknowledging reports notAutoGraded', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      DialogueActivityView(
        activity: _handAuthoredFixture(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.notAutoGraded);
  });
}
