import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/models/media_specification.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/media/scene_diagram.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/features/activity_engine/presentation/views/choice_activity_view.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';

import '../speech/fake_speech_services.dart';
import 'fake_sound_effects_service.dart';
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

  testWidgets('after Check, the correct option fills with the semantic '
      "success colour, not colorScheme.primary — 'correct' must read as "
      "green regardless of the learner's chosen theme", (tester) async {
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (_) {},
      ),
    );

    await tester.tap(find.text('Omar'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final context = tester.element(find.text('Omar'));
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    final colorScheme = Theme.of(context).colorScheme;

    final material = tester
        .widgetList<Material>(
          find.ancestor(of: find.text('Omar'), matching: find.byType(Material)),
        )
        .first;
    expect(material.color, feedbackTheme.successContainer);
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      feedbackTheme.success,
    );
    expect(material.color, isNot(equals(colorScheme.primary)));
  });

  testWidgets(
    'the audio plays automatically the moment the activity appears — no '
    'tap on the Listen button needed',
    (tester) async {
      final fakeTts = FakeTextToSpeechService();
      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: _audioChoice(),
          onSubmitted: (_) {},
        ),
        textToSpeechService: fakeTts,
      );

      expect(fakeTts.spoken, ["Hi, I'm Omar."]);
    },
  );

  testWidgets(
    'does NOT auto-play in review mode — a review screen can show several '
    'of these at once, and nothing here is a live listening exercise',
    (tester) async {
      final fakeTts = FakeTextToSpeechService();
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
            rawAnswer: jsonEncode('Omar'),
            isCorrect: true,
            score: 1.0,
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 9, 9),
            updatedAt: DateTime.utc(2026, 9, 9),
          ),
        ),
        textToSpeechService: fakeTts,
      );

      expect(fakeTts.spoken, isEmpty);
    },
  );

  group('option order is shuffled', () {
    testWidgets(
      'renders options in a shuffled order, not the bundle\'s raw JSON '
      'order — the real A1 bundle has the correct answer as option 0 in '
      '95% of choice activities, making it guessable without a shuffle',
      (tester) async {
        final activity = AudioChoiceActivity(
          id: 'A1-TEST-A01',
          lessonId: 'A1-TEST-L1',
          mode: ActivityMode.mastery,
          skill: Skill.listening,
          canDo: const [],
          prompt: 'Pick one.',
          promptAr: 'اختر واحداً.',
          raw: const {},
          options: const ['a', 'b', 'c', 'd', 'e'],
          answer: 'a',
        );

        await tester.pumpActivityView(
          ChoiceActivityView.audioChoice(
            activity: activity,
            onSubmitted: (_) {},
            // A fixed seed makes the resulting order deterministic and
            // provable in a test — production uses an unseeded Random()
            // (the default when none is injected), so it differs on every
            // real mount.
            random: Random(0),
          ),
        );

        // Random(0).shuffle() on ['a','b','c','d','e'] deterministically
        // produces ['e','c','d','b','a'] — verified directly against
        // dart:math's shuffle implementation.
        final expectedOrder = ['e', 'c', 'd', 'b', 'a'];
        final sortedByPosition =
            [
              for (final option in ['a', 'b', 'c', 'd', 'e']) option,
            ]..sort(
              (x, y) => tester
                  .getTopLeft(find.text(x))
                  .dy
                  .compareTo(tester.getTopLeft(find.text(y)).dy),
            );

        expect(sortedByPosition, expectedOrder);
        expect(
          sortedByPosition,
          isNot(['a', 'b', 'c', 'd', 'e']),
          reason: 'must not render in the original, guessable bundle order',
        );
      },
    );

    testWidgets('the shuffled order stays stable across the activity\'s own '
        'rebuilds (e.g. after selecting an option) — only a fresh mount '
        'reshuffles', (tester) async {
      final activity = AudioChoiceActivity(
        id: 'A1-TEST-A02',
        lessonId: 'A1-TEST-L1',
        mode: ActivityMode.mastery,
        skill: Skill.listening,
        canDo: const [],
        prompt: 'Pick one.',
        promptAr: 'اختر واحداً.',
        raw: const {},
        options: const ['a', 'b', 'c', 'd', 'e'],
        answer: 'a',
      );

      await tester.pumpActivityView(
        ChoiceActivityView.audioChoice(
          activity: activity,
          onSubmitted: (_) {},
          random: Random(0),
        ),
      );

      List<String> currentOrder() =>
          [
            for (final option in ['a', 'b', 'c', 'd', 'e']) option,
          ]..sort(
            (x, y) => tester
                .getTopLeft(find.text(x))
                .dy
                .compareTo(tester.getTopLeft(find.text(y)).dy),
          );

      final beforeSelection = currentOrder();
      await tester.tap(find.text('b'));
      await tester.pump();
      final afterSelection = currentOrder();

      expect(afterSelection, beforeSelection);
    });
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
    'tapping an option only selects it — nothing is graded or revealed '
    'until Check, so a mis-tap can be changed',
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
      await tester.tap(find.text('Omar'));
      await tester.pump();

      expect(reported, isNull);
      expect(find.text('Correct!'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('Check submits the selected option and only then reveals the '
      'result', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tester.tap(find.text('Omar'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
    expect(reported?.score, 1.0);
    expect(find.text('Correct!'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('"Slower" replays the audio at a slower speaking rate', (
    tester,
  ) async {
    final fakeTts = FakeTextToSpeechService();
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (_) {},
      ),
      textToSpeechService: fakeTts,
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    // Let the auto-play finish — both buttons are disabled while playing.
    await tester.pump();

    await tester.tap(find.text(l10n.activityListenSlower));
    await tester.pump();

    expect(fakeTts.spoken, ["Hi, I'm Omar.", "Hi, I'm Omar."]);
    expect(fakeTts.rates[1]!, lessThan(fakeTts.rates[0]!));
  });

  testWidgets('plays the correct sound when submitting the right answer', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (_) {},
      ),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    await tester.tap(find.text('Omar'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(fakeSound.played, [ActivityFeedbackSound.correct]);
  });

  testWidgets('plays the incorrect sound when submitting the wrong answer', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      ChoiceActivityView.audioChoice(
        activity: _audioChoice(),
        onSubmitted: (_) {},
      ),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    await tester.tap(find.text('Maya'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(fakeSound.played, [ActivityFeedbackSound.incorrect]);
  });

  testWidgets('review mode never plays a sound — nothing was just submitted', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
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
          rawAnswer: jsonEncode('Omar'),
          isCorrect: true,
          score: 1.0,
          wasFallback: false,
          attemptedAt: DateTime.utc(2026, 9, 9),
          updatedAt: DateTime.utc(2026, 9, 9),
        ),
      ),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    expect(fakeSound.played, isEmpty);
  });

  testWidgets('checking the wrong option reveals the correct answer for this '
      'activity', (tester) async {
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
  });

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

    testWidgets('a never-graded (isCorrect: null) attempt renders the neutral '
        '"saved for review" treatment, never as incorrect', (tester) async {
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
            rawAnswer: jsonEncode('Omar'),
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
