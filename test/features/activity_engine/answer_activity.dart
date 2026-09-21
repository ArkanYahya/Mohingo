import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/activity_word_tile.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/answer_tile_state.dart';

/// Gives [activity] its own correct answer the way a learner would — tap
/// options, place words, pair items, type text — without pressing Check.
///
/// Shared by every end-to-end test that drives real content through a
/// host screen (lesson player, placement test): unlike a learner, the
/// driver is allowed to know the answer key.
Future<void> enterCorrectAnswer(WidgetTester tester, Activity activity) async {
  switch (activity) {
    case AudioChoiceActivity a:
      // `.last`: some answers coincide with their own audioTranscript text
      // once revealed — the option tile comes after the audio card.
      await tester.tap(find.text(a.answer).last);
    case TextChoiceActivity a:
      await tester.tap(find.text(a.answer).last);
    case GapActivity a:
      // `.first`: a gap activity's distractors can repeat the answer word —
      // either tile is the same choice.
      await tester.tap(find.widgetWithText(ActivityWordTile, a.answer).first);
    case OrderActivity a:
      for (final token in a.answer) {
        await tester.tap(_idleTile(token));
        await tester.pump();
      }
    case MatchActivity a:
      // Only ever tap a still-unpaired tile: tapping a paired one undoes
      // the pair, and a word can appear in both columns.
      for (final pair in a.pairs) {
        await tester.tap(_idleTile(pair[0]));
        await tester.pump();
        await tester.tap(_idleTile(pair[1]));
        await tester.pump();
      }
    case SpeakActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case WriteActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case FormActivity a:
      final fields = find.byType(TextField);
      for (var i = 0; i < a.fields.length; i++) {
        await tester.enterText(fields.at(i), 'an answer');
      }
    case DialogueActivity _:
      break; // no input required
  }
  await tester.pump();
}

/// Gives [activity] an answer that is definitely **not** its answer key —
/// a wrong option, a swapped word order, a crossed-over pairing.
///
/// The mirror of [enterCorrectAnswer], for the end-to-end tests that have
/// to drive a learner who doesn't know the material (the placement test's
/// block pass only stops where a learner gets things wrong). Throws rather
/// than guessing when an activity has no wrong answer to give — a
/// single-token order, a one-pair match — so a test can never quietly pass
/// by answering correctly.
Future<void> enterWrongAnswer(WidgetTester tester, Activity activity) async {
  String otherThan(List<String> options, String answer, String what) {
    for (final option in options) {
      if (option != answer) return option;
    }
    throw StateError('${activity.id}: $what has no wrong option to pick');
  }

  switch (activity) {
    case AudioChoiceActivity a:
      await tester.tap(
        find.text(otherThan(a.options, a.answer, 'audioChoice')).last,
      );
    case TextChoiceActivity a:
      await tester.tap(
        find.text(otherThan(a.options, a.answer, 'textChoice')).last,
      );
    case GapActivity a:
      await tester.tap(
        find
            .widgetWithText(
              ActivityWordTile,
              otherThan(a.options, a.answer, 'gap'),
            )
            .first,
      );
    case OrderActivity a:
      if (a.answer.length < 2) {
        throw StateError('${activity.id}: a 1-token order is always right');
      }
      // The answer with its last two tokens swapped: still every token,
      // in an order the key doesn't accept.
      final wrong = [...a.answer];
      final last = wrong.removeLast();
      wrong.insert(wrong.length - 1, last);
      for (final token in wrong) {
        await tester.tap(_idleTile(token));
        await tester.pump();
      }
    case MatchActivity a:
      if (a.pairs.length < 2) {
        throw StateError('${activity.id}: a 1-pair match is always right');
      }
      // The first two pairs crossed over, the rest as they should be.
      final crossed = [
        [a.pairs[0][0], a.pairs[1][1]],
        [a.pairs[1][0], a.pairs[0][1]],
        ...a.pairs.skip(2),
      ];
      for (final pair in crossed) {
        await tester.tap(_idleTile(pair[0]));
        await tester.pump();
        await tester.tap(_idleTile(pair[1]));
        await tester.pump();
      }
    case SpeakActivity _:
    case WriteActivity _:
    case FormActivity _:
    case DialogueActivity _:
      throw StateError(
        '${activity.id}: productive and dialogue activities are never '
        'scored right or wrong by these tests',
      );
  }
  await tester.pump();
}

/// Answers [activity], taps Check, then taps the button that moves on —
/// the lesson player's Continue, or another host's Next.
Future<void> answerCheckAndAdvance(
  WidgetTester tester,
  Activity activity, {
  bool correctly = true,
}) async {
  // Some activity views (e.g. SpeakActivityView) do an async capability
  // check in initState before their real body renders — settle that first.
  await tester.pumpAndSettle();
  if (correctly) {
    await enterCorrectAnswer(tester, activity);
  } else {
    await enterWrongAnswer(tester, activity);
  }
  await tester.tap(find.byType(FilledButton)); // Check
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FilledButton)); // Continue / Next
  await tester.pumpAndSettle();
}

Finder _idleTile(String label) => find
    .byWidgetPredicate(
      (w) =>
          w is ActivityWordTile &&
          w.label == label &&
          w.state == AnswerTileState.idle &&
          w.onTap != null,
    )
    .last;
