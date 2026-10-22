import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grading_signals.dart';

void main() {
  group('combineSignals', () {
    test('with no signal the rubric score is the final score', () {
      for (final base in [0.0, 0.5, 0.75, 1.0]) {
        expect(combineSignals(GradingSignals(rubric: base)), base);
      }
    });

    test('a rubric score of 0 can never pass, whatever the signals say', () {
      final best = combineSignals(
        const GradingSignals(
          rubric: 0,
          meaning: 1,
          grammarPenalty: 0,
          meaningOk: true,
        ),
      );
      expect(best, closeTo(0.25, 1e-9));
      expect(best, lessThan(kFreeAnswerPassScore));
    });

    test('a rubric score of 1 can never fall below the pass bar', () {
      final worst = combineSignals(
        const GradingSignals(
          rubric: 1,
          meaning: 0,
          grammarPenalty: 1,
          meaningOk: false,
        ),
      );
      expect(worst, closeTo(0.75, 1e-9));
      expect(worst, greaterThanOrEqualTo(kFreeAnswerPassScore));
    });

    test('a full meaning match adds a quarter, and only when the rubric '
        'left room', () {
      expect(
        combineSignals(const GradingSignals(rubric: 0.5, meaning: 1)),
        closeTo(0.75, 1e-9),
      );
      expect(
        combineSignals(const GradingSignals(rubric: 1, meaning: 1)),
        1.0,
        reason: 'a rubric that is already full gains nothing from meaning',
      );
      expect(
        combineSignals(const GradingSignals(rubric: 0.5, meaning: 0.4)),
        closeTo(0.6, 1e-9),
      );
    });

    test('grammar subtracts in proportion to the penalty', () {
      expect(
        combineSignals(const GradingSignals(rubric: 1, grammarPenalty: 0.5)),
        closeTo(0.875, 1e-9),
      );
      expect(
        combineSignals(const GradingSignals(rubric: 1, grammarPenalty: 0)),
        1.0,
      );
    });

    test('the judgement moves the score a tenth either way', () {
      expect(
        combineSignals(const GradingSignals(rubric: 0.7, meaningOk: true)),
        closeTo(0.8, 1e-9),
      );
      expect(
        combineSignals(const GradingSignals(rubric: 0.8, meaningOk: false)),
        closeTo(0.7, 1e-9),
      );
    });

    test('the total adjustment is clamped to a quarter of the scale', () {
      // +0.25 (meaning) + 0.10 (judgement) would be 0.35; clamped to 0.25.
      expect(
        combineSignals(
          const GradingSignals(rubric: 0.5, meaning: 1, meaningOk: true),
        ),
        closeTo(0.75, 1e-9),
      );
      // −0.25 (grammar) − 0.10 (judgement) would be −0.35; clamped to −0.25.
      expect(
        combineSignals(
          const GradingSignals(rubric: 1, grammarPenalty: 1, meaningOk: false),
        ),
        closeTo(0.75, 1e-9),
      );
    });

    test('inputs outside 0..1 are clamped rather than trusted', () {
      expect(
        combineSignals(const GradingSignals(rubric: 0.5, meaning: 7)),
        closeTo(0.75, 1e-9),
      );
      expect(combineSignals(const GradingSignals(rubric: 1.5)), 1.0);
    });

    test('is deterministic', () {
      const s = GradingSignals(
        rubric: 0.667,
        meaning: 0.42,
        grammarPenalty: 0.1,
        meaningOk: true,
      );
      expect(combineSignals(s), combineSignals(s));
    });
  });

  group('grammarPenaltyOf', () {
    test('four issues in a hundred words is the maximum penalty', () {
      expect(grammarPenaltyOf(errorCount: 25, wordCount: 100), 1.0);
      expect(
        grammarPenaltyOf(errorCount: 1, wordCount: 100),
        closeTo(0.04, 1e-9),
      );
      expect(grammarPenaltyOf(errorCount: 0, wordCount: 30), 0.0);
    });

    test('an empty report never divides by zero', () {
      expect(grammarPenaltyOf(errorCount: 0, wordCount: 0), 0.0);
      expect(grammarPenaltyOf(errorCount: 1, wordCount: 0), 1.0);
    });
  });

  group('criteriaScoresJson / explanationIn', () {
    test('records every present signal and the final score', () {
      final json = criteriaScoresJson(
        const GradingSignals(
          rubric: 0.5,
          meaning: 0.9,
          grammarPenalty: 0.0,
          meaningOk: true,
          pack: 'gemma-3n-e2b-1',
        ),
        finalScore: 0.75,
        explanationEn: 'Good: you said when and how often.',
        explanationAr: 'جيد: ذكرت الوقت والتكرار.',
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['rubric'], 0.5);
      expect(decoded['meaning'], 0.9);
      expect(decoded['grammar'], 0.0);
      expect(decoded['judgement'], true);
      expect(decoded['pack'], 'gemma-3n-e2b-1');
      expect(decoded['final'], 0.75);
      expect(explanationIn(json), (
        en: 'Good: you said when and how often.',
        ar: 'جيد: ذكرت الوقت والتكرار.',
      ));
    });

    test('leaves absent signals and empty explanations out', () {
      final json = criteriaScoresJson(
        const GradingSignals(rubric: 1),
        finalScore: 1,
        explanationEn: '',
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded.keys, unorderedEquals(['rubric', 'final']));
      expect(explanationIn(json), isNull);
    });

    test('reads nothing from a null, non-JSON or pre-0011 string', () {
      expect(explanationIn(null), isNull);
      expect(explanationIn('not json'), isNull);
      expect(explanationIn('{"listening": 0.8}'), isNull);
      expect(explanationIn('[1, 2]'), isNull);
    });
  });
}
