import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/models/media_specification.dart';
import 'package:mohingo/core/media/scene_diagram.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/choice_activity_view.dart';

import 'test_harness.dart';

AudioChoiceActivity _audioChoice({bool mediaOptions = false}) {
  return AudioChoiceActivity(
    id: 'A1-U1-L1-A01',
    lessonId: 'A1-U1-L1',
    mode: ActivityMode.mastery,
    skill: Skill.listening,
    canDo: const ['A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO'],
    prompt: "What's the man's name?",
    promptAr: 'ما اسم الرجل؟',
    raw: {if (mediaOptions) 'optionMode': 'media'},
    options: const ['Omar', 'Maya', 'Sami'],
    answer: 'Omar',
    audioTranscript: "Hi, I'm Omar.",
  );
}

void main() {
  testWidgets(
    'renders prompt, promptAr, options, and the transcript help card',
    (tester) async {
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (_) {},
        ),
      );

      expect(find.text("What's the man's name?"), findsOneWidget);
      expect(find.text('ما اسم الرجل؟'), findsOneWidget);
      expect(find.text('Omar'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text("Hi, I'm Omar."), findsOneWidget);
    },
  );

  testWidgets('submit button is disabled until an option is selected', (
    tester,
  ) async {
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (_) {},
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'selecting the correct option and submitting reports correct, and '
    'reveals the answer only after submission',
    (tester) async {
      ActivitySubmission? reported;
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (s) => reported = s,
        ),
      );

      // Before submission: no feedback banner, no "Correct!" text anywhere.
      expect(find.text('Correct!'), findsNothing);

      await tester.tap(find.text('Omar'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(reported?.correctness, ActivityCorrectness.correct);
      expect(reported?.score, 1.0);
      expect(find.text('Correct!'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting the wrong option reports incorrect and reveals the correct '
    'answer for this activity',
    (tester) async {
      ActivitySubmission? reported;
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (s) => reported = s,
        ),
      );

      await tester.tap(find.text('Maya'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(reported?.correctness, ActivityCorrectness.incorrect);
      expect(find.textContaining('Omar'), findsWidgets);
    },
  );

  testWidgets(
    'optionMode "media" renders each option via SceneDiagram, not plain text',
    (tester) async {
      final spec = MediaSpecification.fromJson({
        'type': 'peopleCard',
        'alt': 'x',
        'render': {
          'people': [
            {'id': 'p1', 'role': 'parent'},
          ],
          'links': [],
        },
      });

      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(mediaOptions: true),
          onSubmitted: (_) {},
          mediaByKey: {'Omar': spec},
        ),
      );

      expect(find.byType(SceneDiagram), findsWidgets);
    },
  );
}
