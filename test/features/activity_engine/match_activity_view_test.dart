import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/match_activity_view.dart';

import 'test_harness.dart';

MatchActivity _matchActivity() {
  return const MatchActivity(
    id: 'A1-U2-L1-A02',
    lessonId: 'A1-U2-L1',
    mode: ActivityMode.practice,
    skill: Skill.reading,
    canDo: ['A1.U2.PRODUCTION.STATE_RELATIONSHIP'],
    prompt: 'Match the people and relationships.',
    promptAr: 'طابق الأشخاص بصلة القرابة.',
    raw: {},
    pairs: [
      ['Lina', 'mother'],
      ['Sami', 'father'],
    ],
  );
}

void main() {
  testWidgets('renders every left and right item', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('Sami'), findsOneWidget);
    expect(find.text('mother'), findsOneWidget);
    expect(find.text('father'), findsOneWidget);
  });

  testWidgets('submit is disabled until every left item is matched', (
    tester,
  ) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Lina'));
    await tester.pump();
    await tester.tap(find.text('mother'));
    await tester.pump();

    // Only 1 of 2 pairs matched so far.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('matching every pair correctly reports correct', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      MatchActivityView(
        activity: _matchActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.tap(find.text('Lina'));
    await tester.pump();
    await tester.tap(find.text('mother'));
    await tester.pump();
    await tester.tap(find.text('Sami'));
    await tester.pump();
    await tester.tap(find.text('father'));
    await tester.pump();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
  });
}
