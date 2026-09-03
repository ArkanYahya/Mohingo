import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/order_activity_view.dart';

import 'test_harness.dart';

OrderActivity _orderActivity() {
  return const OrderActivity(
    id: 'A1-U2-L1-A03',
    lessonId: 'A1-U2-L1',
    mode: ActivityMode.practice,
    skill: Skill.reading,
    canDo: ['A1.U2.PRODUCTION.DESCRIBE_FAMILY'],
    prompt: 'Build the sentence.',
    promptAr: 'رتب الجملة.',
    raw: {},
    tokens: ['is', 'This', 'mother', 'my'],
    answer: ['This', 'is', 'my', 'mother'],
  );
}

void main() {
  testWidgets('renders every token as a tappable chip', (tester) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );

    for (final token in ['is', 'This', 'mother', 'my']) {
      expect(find.text(token), findsOneWidget);
    }
  });

  testWidgets('tapping tokens in the correct order reports correct', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      OrderActivityView(
        activity: _orderActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    for (final token in ['This', 'is', 'my', 'mother']) {
      await tester.tap(find.text(token));
      await tester.pump();
    }

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
  });

  testWidgets('tapping tokens in the wrong order reports incorrect', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      OrderActivityView(
        activity: _orderActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    for (final token in ['is', 'This', 'my', 'mother']) {
      await tester.tap(find.text(token));
      await tester.pump();
    }

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.incorrect);
  });

  testWidgets('tapping a placed token removes it, allowing re-order', (
    tester,
  ) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );

    await tester.tap(find.text('is')); // place "is" first (wrong start)
    await tester.pump();
    // "is" now appears once in the placed row (as an ActionChip) — tap it
    // to remove it again.
    await tester.tap(find.text('is'));
    await tester.pump();

    // Submit should still be disabled — nothing is placed.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
