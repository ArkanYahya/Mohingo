import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grading_signals.dart';

void main() {
  const spec = KeywordChecklistEvaluationSpec(
    requiredGroups: [
      ['like', 'love'],
      ["don't like", 'dont like', 'hate'],
    ],
    minGroupsMatched: 2,
    meanings: [
      GroupMeaning(
        hypothesis: 'The speaker says two things they like.',
        labelEn: 'two things you like',
        labelAr: 'شيئين تحبّهما',
      ),
      GroupMeaning(
        hypothesis: 'The speaker says one thing they do not like.',
        labelEn: "one thing you don't like",
        labelAr: 'شيئاً لا تحبّه',
      ),
    ],
  );

  group('keywordGroupMatches', () {
    test('one flag per group, in order, by the rubric\'s own matching', () {
      expect(keywordGroupMatches(spec, "I like tea but I can't stand milk."), [
        true,
        false,
      ]);
      expect(keywordGroupMatches(spec, 'I hate milk.'), [false, true]);
      expect(keywordGroupMatches(spec, 'The weather is nice.'), [false, false]);
    });

    test('agrees with evaluate()', () {
      const answer = 'I like tea. I hate milk.';
      final flags = keywordGroupMatches(spec, answer);
      expect(flags.where((f) => f).length, 2);
      expect(evaluate(spec, answer).score, 1.0);
    });
  });

  group('groupsMet and meaningFromParts (ADR 0014)', () {
    test('a group is met by its words or by entailment at the threshold', () {
      expect(groupsMet(metByKeyword: [true, false], entailment: [0.1, 0.95]), [
        true,
        true,
      ]);
      expect(
        groupsMet(
          metByKeyword: [true, false],
          entailment: [0.1, kEntailmentThreshold],
        ),
        [true, true],
      );
      expect(groupsMet(metByKeyword: [true, false], entailment: [0.1, 0.49]), [
        true,
        false,
      ]);
    });

    test('the signal is the share of groups met', () {
      // "I like tea and I love coffee, but I can't stand milk.": the first
      // group by its words, the second by its meaning → 1.0, which with the
      // rubric's 0.5 and the 0.25 weight reaches exactly the pass bar.
      final meaning = meaningFromParts(
        metByKeyword: [true, false],
        entailment: [0.98, 0.98],
      );
      expect(meaning, 1.0);
      expect(
        combineSignals(GradingSignals(rubric: 0.5, meaning: meaning)),
        kFreeAnswerPassScore,
      );
      // "I like football and I love music. I like tennis too.": the dislike
      // is neither said nor meant → 0.5, and 0.5 + 0.125 fails.
      final missingDislike = meaningFromParts(
        metByKeyword: [true, false],
        entailment: [0.89, 0.04],
      );
      expect(missingDislike, 0.5);
      expect(
        combineSignals(GradingSignals(rubric: 0.5, meaning: missingDislike)),
        lessThan(kFreeAnswerPassScore),
      );
      // Off topic: nothing by words, nothing by meaning.
      expect(
        meaningFromParts(
          metByKeyword: [false, false],
          entailment: [0.07, 0.07],
        ),
        0,
      );
      expect(meaningFromParts(metByKeyword: [], entailment: []), 0);
    });

    test('a shorter entailment list leaves the rest to the words', () {
      expect(groupsMet(metByKeyword: [false, true], entailment: [0.9]), [
        true,
        true,
      ]);
    });
  });

  group('missingMeanings', () {
    test('names the groups met neither way, in order', () {
      final missing = missingMeanings(
        meanings: spec.meanings!,
        metByKeyword: [true, false],
        entailment: [0.9, 0.04],
      );
      expect(missing.map((m) => m.labelEn), ["one thing you don't like"]);
      expect(
        missingMeanings(
          meanings: spec.meanings!,
          metByKeyword: [false, false],
          entailment: [0.1, 0.1],
        ).length,
        2,
      );
      expect(
        missingMeanings(
          meanings: spec.meanings!,
          metByKeyword: [true, true],
          entailment: [0.0, 0.0],
        ),
        isEmpty,
      );
    });
  });

  test('criteriaScoresJson records the parts and the explanation', () {
    final json = criteriaScoresJson(
      const GradingSignals(rubric: 0.5, meaning: 1.0),
      finalScore: 0.75,
      parts: [0.98, 0.97],
      explanationEn: "Your answer is missing: one thing you don't like.",
      explanationAr: 'ينقص جوابك: شيئاً لا تحبّه.',
    );
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['parts'], [0.98, 0.97]);
    expect(decoded['final'], 0.75);
    final explanation = explanationIn(json)!;
    expect(explanation.en, startsWith('Your answer is missing'));
    expect(explanation.ar, startsWith('ينقص جوابك'));
    expect(
      jsonDecode(
        criteriaScoresJson(const GradingSignals(rubric: 1), finalScore: 1),
      ),
      isNot(contains('parts')),
    );
  });
}
