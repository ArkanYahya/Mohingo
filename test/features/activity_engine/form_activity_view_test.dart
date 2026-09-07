import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/form_activity_view.dart';

import 'test_harness.dart';

FormActivity _formActivity() {
  return const FormActivity(
    id: 'A1-U2-L7-A01',
    lessonId: 'A1-U2-L7',
    mode: ActivityMode.mastery,
    skill: Skill.writing,
    canDo: ['A1.U2.MEDIATION.EXPLAIN_PEOPLE_MAP'],
    prompt: 'Create four people cards.',
    promptAr: 'أنشئ أربع بطاقات لأشخاص.',
    raw: {},
    fields: ['name', 'relationship'],
  );
}

void main() {
  testWidgets('renders one text field per declared field name', (tester) async {
    await tester.pumpActivityView(
      FormActivityView(activity: _formActivity(), onSubmitted: (_) {}),
    );

    expect(find.widgetWithText(TextField, 'name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'relationship'), findsOneWidget);
  });

  testWidgets('submit is disabled until every field is filled', (tester) async {
    await tester.pumpActivityView(
      FormActivityView(activity: _formActivity(), onSubmitted: (_) {}),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('a completed form always reports notAutoGraded', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      FormActivityView(
        activity: _formActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Lina');
    await tester.enterText(find.byType(TextField).last, 'mother');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.notAutoGraded);
  });
}
