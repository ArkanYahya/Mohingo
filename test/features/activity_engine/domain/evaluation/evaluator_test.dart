import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_context.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';

void main() {
  group('nonEmpty', () {
    test('a non-blank answer is correct', () {
      final result = evaluate(const NonEmptyEvaluationSpec(), 'Ali');
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('a blank answer is incorrect', () {
      final result = evaluate(const NonEmptyEvaluationSpec(), '   ');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.0);
    });
  });

  group('numericRange', () {
    const spec = NumericRangeEvaluationSpec(min: 1, max: 120);

    test('a number inside the range is correct', () {
      final result = evaluate(spec, "I'm 25 years old.");
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a number outside the range is incorrect', () {
      final result = evaluate(spec, '999');
      expect(result.correctness, ActivityCorrectness.incorrect);
    });

    test('no number at all is incorrect', () {
      final result = evaluate(spec, 'old enough');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.0);
    });
  });

  group('letterSequence', () {
    test('a profileName reference matches the context\'s profile name', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: ProfileNameReference(),
      );
      final result = evaluate(
        spec,
        'a l i',
        context: const EvaluationContext(profileName: 'Ali'),
      );
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a profileName reference falls back to a non-empty check when no '
        'name is set yet', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: ProfileNameReference(),
      );
      final result = evaluate(spec, 'a l i');
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a previousAnswer reference matches the referenced activity\'s '
        'stored answer', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: PreviousAnswerReference('A1-U0-L5-A01'),
      );
      final result = evaluate(
        spec,
        'a l i',
        context: const EvaluationContext(
          previousAnswers: {'A1-U0-L5-A01': 'Ali'},
        ),
      );
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a previousAnswer reference with nothing recorded yet is '
        'not-auto-graded, not falsely correct', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: PreviousAnswerReference('A1-U0-L5-A01'),
      );
      final result = evaluate(spec, 'a l i');
      expect(result.correctness, ActivityCorrectness.notAutoGraded);
    });

    test('a mismatched letter sequence is incorrect', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: LiteralReference('Ali'),
      );
      final result = evaluate(spec, 'a l e');
      expect(result.correctness, ActivityCorrectness.incorrect);
    });
  });

  group('keywordChecklist', () {
    const spec = KeywordChecklistEvaluationSpec(
      requiredGroups: [
        ['hi', 'hello'],
        ['weekend', 'saturday', 'sunday'],
      ],
      minGroupsMatched: 2,
    );

    test('meeting every required group is correct', () {
      final result = evaluate(spec, 'Hello! See you this weekend.');
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('meeting fewer than the threshold is incorrect, with a partial '
        'score', () {
      final result = evaluate(spec, 'Hello there.');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.5);
    });
  });
}
