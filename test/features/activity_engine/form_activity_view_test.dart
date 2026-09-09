import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
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

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'pre-fills the recorded field values, disabled, with the neutral '
      'saved-for-review treatment — no submit button',
      (tester) async {
        await tester.pumpActivityView(
          FormActivityView(
            activity: _formActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L7-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing',
              rawAnswer: jsonEncode({'name': 'Lina', 'relationship': 'mother'}),
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.text('Lina'), findsOneWidget);
        expect(find.text('mother'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

        final nameField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(nameField.enabled, isFalse);
      },
    );
  });
}
