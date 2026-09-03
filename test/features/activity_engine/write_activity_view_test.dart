import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/write_activity_view.dart';

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
    evaluation: 'u2-people-profile-rubric',
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
  testWidgets('shows the word-count guide when declared', (tester) async {
    await tester.pumpActivityView(
      WriteActivityView(activity: _openEndedWrite(), onSubmitted: (_) {}),
    );
    expect(find.textContaining('25'), findsOneWidget);
    expect(find.textContaining('45'), findsOneWidget);
  });

  testWidgets('an open-ended write (no accepted list) is notAutoGraded', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      WriteActivityView(
        activity: _openEndedWrite(),
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
}
