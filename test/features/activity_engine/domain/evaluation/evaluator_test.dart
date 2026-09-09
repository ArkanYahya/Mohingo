import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_context.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
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

    group('a reference with no Latin letters at all', () {
      // The app's learners are Arabic speakers, so a name saved in Settings
      // is plausibly Arabic script. Letters-only comparison only understands
      // Latin letters, so such a reference normalizes to '' — it must be
      // treated as "no usable reference", not silently compared against ''
      // (which could never match and would make A1-U0-L3-A04 permanently
      // ungradeable, blocking A1.U0.PRODUCTION.SPELL_NAME and all of A1-U0).
      test('a profileName reference softens to the non-empty fallback', () {
        const spec = LetterSequenceEvaluationSpec(
          reference: ProfileNameReference(),
        );
        // The regression: a learner saved "علي" and spells it back in Latin
        // letters, as A1-U0-L3-A04 ("Spell your name.") asks. Comparing
        // against the raw reference marks this — and every other answer —
        // wrong forever, making A1.U0.PRODUCTION.SPELL_NAME unmasterable.
        expect(
          evaluate(
            spec,
            'a l i',
            context: const EvaluationContext(profileName: 'علي'),
          ).correctness,
          ActivityCorrectness.correct,
        );
        expect(
          evaluate(
            spec,
            'ع ل ي',
            context: const EvaluationContext(profileName: 'علي'),
          ).correctness,
          ActivityCorrectness.correct,
        );
      });

      test('the non-empty fallback still rejects a blank answer', () {
        const spec = LetterSequenceEvaluationSpec(
          reference: ProfileNameReference(),
        );
        final result = evaluate(
          spec,
          '   ',
          context: const EvaluationContext(profileName: 'علي'),
        );
        expect(result.correctness, ActivityCorrectness.incorrect);
      });

      test('a previousAnswer reference is not-auto-graded, not falsely '
          'correct', () {
        const spec = LetterSequenceEvaluationSpec(
          reference: PreviousAnswerReference('A1-U0-L5-A01'),
        );
        final result = evaluate(
          spec,
          'a l i',
          context: const EvaluationContext(
            previousAnswers: {'A1-U0-L5-A01': 'علي'},
          ),
        );
        expect(result.correctness, ActivityCorrectness.notAutoGraded);
      });

      test('a literal reference is not-auto-graded, not falsely correct', () {
        const spec = LetterSequenceEvaluationSpec(
          reference: LiteralReference('١٢٣'),
        );
        final result = evaluate(spec, 'a l i');
        expect(result.correctness, ActivityCorrectness.notAutoGraded);
      });
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

    test('a keyword buried inside an unrelated word does not count as a '
        'match', () {
      // "this" contains the substring "hi" and "sunday" contains "sun" —
      // a plain contains() check would score this answer 1.0 despite it
      // greeting nobody and naming no day.
      final result = evaluate(spec, 'I would like this class.');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.0);
    });

    test('the same keyword as a standalone word still matches', () {
      final result = evaluate(spec, 'Hi! I am free on Saturday.');
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('a multi-word keyword phrase matches as a phrase', () {
      const phraseSpec = KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hello', 'good morning'],
        ],
        minGroupsMatched: 1,
      );
      expect(
        evaluate(phraseSpec, 'Good morning, teacher.').correctness,
        ActivityCorrectness.correct,
      );
      expect(
        evaluate(phraseSpec, 'Good afternoon, teacher.').correctness,
        ActivityCorrectness.incorrect,
      );
      // The phrase is boundary-anchored at both ends, not just the start.
      expect(
        evaluate(phraseSpec, 'Have a good morningtime.').correctness,
        ActivityCorrectness.incorrect,
      );
    });

    test('meeting exactly minGroupsMatched scores a full 1.0 even when the '
        'rubric lists more groups than it requires', () {
      // The real A1-U5-L6-A05 shape: "mention any 2 of these 3 things."
      const twoOfThree = KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
          ['weekend', 'saturday'],
          ['park', 'cinema'],
        ],
        minGroupsMatched: 2,
      );

      final result = evaluate(twoOfThree, 'Hello! See you on Saturday.');

      expect(result.correctness, ActivityCorrectness.correct);
      expect(
        result.score,
        1.0,
        reason:
            'scoring against the group count instead of the pass bar would '
            'give 0.667 — below MasteryPolicy.minimumObjectiveScore (0.75), '
            'so MasteryAggregationService would refuse a rubric-passing '
            'answer as evidence',
      );
    });

    test('covering more groups than required never scores above 1.0', () {
      const twoOfThree = KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
          ['weekend', 'saturday'],
          ['park', 'cinema'],
        ],
        minGroupsMatched: 2,
      );

      final result = evaluate(
        twoOfThree,
        'Hello! See you at the park on Saturday.',
      );

      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('falling short of the pass bar still scores proportionally', () {
      const twoOfThree = KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
          ['weekend', 'saturday'],
          ['park', 'cinema'],
        ],
        minGroupsMatched: 2,
      );

      final result = evaluate(twoOfThree, 'Hello there.');

      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.5); // 1 of the 2 required groups
    });

    test('the A1-U0-L5-A05 shape: a greeting plus registration intent', () {
      const registerSpec = KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hello', 'hi', 'good morning', 'good afternoon', 'good evening'],
          ['join', 'register', 'class', 'english', 'sign up'],
        ],
        minGroupsMatched: 2,
      );
      expect(
        evaluate(
          registerSpec,
          'Hello, I want to join the English class.',
        ).correctness,
        ActivityCorrectness.correct,
      );
      // Registration intent but no greeting — must not pass on "th-i-s".
      expect(
        evaluate(registerSpec, 'I want to join this class.').correctness,
        ActivityCorrectness.incorrect,
      );
      // A greeting alone is not enough either.
      expect(
        evaluate(registerSpec, 'Hello there!').correctness,
        ActivityCorrectness.incorrect,
      );
    });
  });

  group('expectedAnswerLabel', () {
    test('nonEmpty has no single fixed answer to reveal', () {
      expect(
        expectedAnswerLabel(
          const NonEmptyEvaluationSpec(),
          const EvaluationContext.empty(),
        ),
        isNull,
      );
    });

    test('numericRange reveals the accepted range', () {
      expect(
        expectedAnswerLabel(
          const NumericRangeEvaluationSpec(min: 1, max: 120),
          const EvaluationContext.empty(),
        ),
        '1–120',
      );
    });

    test('numericRange drops a trailing .0 from whole-number bounds, but '
        'keeps a genuine fraction', () {
      expect(
        expectedAnswerLabel(
          const NumericRangeEvaluationSpec(min: 0.5, max: 3),
          const EvaluationContext.empty(),
        ),
        '0.5–3',
      );
    });

    test('letterSequence with a resolved profileName reveals the name as '
        'saved, not letters-only-normalized', () {
      expect(
        expectedAnswerLabel(
          const LetterSequenceEvaluationSpec(reference: ProfileNameReference()),
          const EvaluationContext(profileName: 'Arkan'),
        ),
        'Arkan',
      );
    });

    test('letterSequence with a resolved previousAnswer reveals it', () {
      expect(
        expectedAnswerLabel(
          const LetterSequenceEvaluationSpec(
            reference: PreviousAnswerReference('A1-U0-L5-A01'),
          ),
          const EvaluationContext(previousAnswers: {'A1-U0-L5-A01': 'Ali'}),
        ),
        'Ali',
      );
    });

    test('letterSequence with no usable reference has nothing to reveal', () {
      expect(
        expectedAnswerLabel(
          const LetterSequenceEvaluationSpec(reference: ProfileNameReference()),
          const EvaluationContext.empty(),
        ),
        isNull,
      );
    });

    test('keywordChecklist has no single fixed answer to reveal — it '
        'grades open-ended text against a checklist, not one string', () {
      expect(
        expectedAnswerLabel(
          const KeywordChecklistEvaluationSpec(
            requiredGroups: [
              ['hi', 'hello'],
            ],
            minGroupsMatched: 1,
          ),
          const EvaluationContext.empty(),
        ),
        isNull,
      );
    });
  });
}
