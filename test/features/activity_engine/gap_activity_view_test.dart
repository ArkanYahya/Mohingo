import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/gap_activity_view.dart';

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

  testWidgets('choosing the correct option reports correct', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      GapActivityView(
        activity: _gapActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'has'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
  });
}
