import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/answer_matching.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';
import 'package:mohingo/features/activity_engine/domain/spoken_answer.dart';

/// Grading a speech transcript: by what was said, not how the recogniser
/// spelled it. The typed path in `answer_matching_test.dart` and
/// `evaluator_test.dart` is unchanged. ADR 0009.
void main() {
  const sara = SpokenAnswer(names: {'sara'});

  group('answersMatch with a spoken answer', () {
    test("the learner's own case: Sara heard as Sarah", () {
      const accepted = "This is Sara. She's my friend.";
      const heard = "this is Sarah she's my friend";
      expect(answersMatch(accepted, heard), isFalse, reason: 'typed');
      expect(answersMatch(accepted, heard, spoken: sara), isTrue);
    });

    test('a name is only forgiven when the task names it', () {
      expect(
        answersMatch(
          'This is Sara.',
          'this is Sarah',
          spoken: const SpokenAnswer(),
        ),
        isFalse,
      );
    });

    test('homophones and digits are the words they sound like', () {
      expect(
        answersMatch('I have two sisters.', 'I have to sisters', spoken: sara),
        isTrue,
      );
      expect(
        answersMatch('I get up at seven.', 'I get up at 7', spoken: sara),
        isTrue,
      );
    });

    test('an ordinary word is still the word, not its sound', () {
      expect(
        answersMatch('I have a bag.', 'I have a big', spoken: sara),
        isFalse,
      );
      expect(
        answersMatch("She's my friend.", "He's my friend", spoken: sara),
        isFalse,
      );
    });

    test('a missing or extra word still fails', () {
      expect(answersMatch('This is Sara.', 'this is', spoken: sara), isFalse);
      expect(
        answersMatch('This is Sara.', 'this is Sara yes', spoken: sara),
        isFalse,
      );
    });
  });

  group('keywordChecklist with a spoken answer', () {
    final spec = EvaluationSpec.fromJson({
      'type': 'keywordChecklist',
      'requiredGroups': [
        ['this is sara', 'sara'],
        ["she's my friend", 'she is my friend', 'my friend', 'friend'],
      ],
      'minGroupsMatched': 2,
    })!;

    test("the learner's own case passes the task's rubric", () {
      const heard = "this is Sarah she's my friend";
      expect(evaluate(spec, heard).correctness, ActivityCorrectness.incorrect);
      final result = evaluate(spec, heard, spoken: sara);
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('a keyword phrase must appear in order, as said', () {
      expect(
        evaluate(spec, 'my friend is Sarah, this is', spoken: sara).correctness,
        ActivityCorrectness.correct, // "sara" and "my friend" both appear
      );
      expect(
        evaluate(spec, 'friend', spoken: sara).correctness,
        ActivityCorrectness.incorrect,
      );
    });

    test("a rubric's contraction meets the transcript's full form", () {
      final spec = EvaluationSpec.fromJson({
        'type': 'keywordChecklist',
        'requiredGroups': [
          ["i don't understand"],
        ],
        'minGroupsMatched': 1,
      })!;
      expect(
        evaluate(spec, 'sorry, I do not understand', spoken: sara).correctness,
        ActivityCorrectness.correct,
      );
    });

    test('a keyword with a number meets the transcript in digits', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'keywordChecklist',
        'requiredGroups': [
          ['at seven', 'at eight'],
        ],
        'minGroupsMatched': 1,
      })!;
      expect(
        evaluate(spec, 'I have breakfast at 7', spoken: sara).correctness,
        ActivityCorrectness.correct,
      );
      expect(
        evaluate(spec, 'I have breakfast at 7').correctness,
        ActivityCorrectness.incorrect, // typed: written as written
      );
    });
  });

  group('numericRange, spoken or typed', () {
    final spec = EvaluationSpec.fromJson({
      'type': 'numericRange',
      'min': 1,
      'max': 120,
    })!;

    test('a number in words grades like the same number in digits', () {
      expect(
        evaluate(spec, "I'm twenty-five.").correctness,
        ActivityCorrectness.correct,
      );
      expect(
        evaluate(spec, 'I am 25').correctness,
        ActivityCorrectness.correct,
      );
      expect(
        evaluate(spec, 'one hundred and thirty').correctness,
        ActivityCorrectness.incorrect,
      );
      expect(
        evaluate(spec, 'no idea').correctness,
        ActivityCorrectness.incorrect,
      );
    });
  });
}
