import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/models/media_specification.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/media/scene_diagram.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/views/choice_activity_view.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';

import '../speech/fake_speech_services.dart';
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
  testWidgets('renders prompt, promptAr, options, and the transcript help card '
      'with the transcript text hidden until revealed', (tester) async {
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
    // The transcript is the whole point of a listening exercise — it must
    // not be readable before the learner chooses to reveal it.
    expect(find.text("Hi, I'm Omar."), findsNothing);
  });

  group('audio transcript reveal', () {
    testWidgets('tapping "Show transcript" reveals the transcript text', (
      tester,
    ) async {
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (_) {},
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      await tester.tap(find.text(l10n.activityShowTranscript));
      await tester.pump();

      expect(find.text("Hi, I'm Omar."), findsOneWidget);
      expect(find.text(l10n.activityShowTranscript), findsNothing);
    });

    testWidgets('a TTS playback error auto-reveals the transcript, so a broken '
        'engine never leaves the exercise unusable', (tester) async {
      final fakeTts = FakeTextToSpeechService();
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (_) {},
        ),
        textToSpeechService: fakeTts,
      );

      expect(find.text("Hi, I'm Omar."), findsNothing);

      fakeTts.emitPlaybackState(TtsPlaybackState.error);
      await tester.pump();

      expect(find.text("Hi, I'm Omar."), findsOneWidget);
    });
  });

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

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no live interaction, no submit button',
      (tester) async {
        await tester.pumpActivityView(
          ChoiceActivityView.audioChoice(
            activity: _audioChoice(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U1-L1-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              rawAnswer: jsonEncode('Omar'), // the actually-correct answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        // Trusts the recorded isCorrect, never re-evaluates "Omar" == answer.
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });
}
