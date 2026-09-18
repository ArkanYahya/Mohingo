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

/// Answers [activity], taps Check, then taps the button that moves on —
/// the lesson player's Continue, or another host's Next.
Future<void> answerCheckAndAdvance(
  WidgetTester tester,
  Activity activity,
) async {
  // Some activity views (e.g. SpeakActivityView) do an async capability
  // check in initState before their real body renders — settle that first.
  await tester.pumpAndSettle();
  await enterCorrectAnswer(tester, activity);
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
