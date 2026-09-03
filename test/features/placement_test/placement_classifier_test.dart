import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/placement_test/domain/placement_classifier.dart';
import 'package:mohingo/features/placement_test/domain/placement_outcome.dart';

void main() {
  group('PlacementScoring.unitPassed', () {
    test('never fails a unit from a single item — insufficient sample size '
        'always passes', () {
      expect(PlacementScoring.unitPassed([false]), isTrue);
      expect(PlacementScoring.unitPassed([]), isTrue);
    });

    test('2 items, 1 correct (50%) fails — below the 0.6 threshold', () {
      expect(PlacementScoring.unitPassed([true, false]), isFalse);
    });

    test('2 items, both correct passes', () {
      expect(PlacementScoring.unitPassed([true, true]), isTrue);
    });

    test('3 items, 2 correct (66%) passes — at/above the 0.6 threshold', () {
      expect(PlacementScoring.unitPassed([true, true, false]), isTrue);
    });
  });

  group('PlacementClassifier.classify — all 4 outcomes reachable', () {
    test('failing at A1-U0 -> startWithEssentials', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', false),
      ]);
      expect(result.outcome, PlacementOutcome.startWithEssentials);
      expect(result.recommendedUnitId, 'A1-U0');
    });

    test('passing A1-U0, failing A1-U1 -> startA1FromU1', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', false),
      ]);
      expect(result.outcome, PlacementOutcome.startA1FromU1);
      expect(result.recommendedUnitId, 'A1-U1');
    });

    test('passing through A1-U4, failing A1-U5 -> startFromRecommendedUnit '
        'at A1-U5, never auto-skipping ahead further', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', true),
        const MapEntry('A1-U2', true),
        const MapEntry('A1-U3', true),
        const MapEntry('A1-U4', true),
        const MapEntry('A1-U5', false),
      ]);
      expect(result.outcome, PlacementOutcome.startFromRecommendedUnit);
      expect(result.recommendedUnitId, 'A1-U5');
    });

    test('passing every scanned unit -> a1Mastered, never a fabricated '
        'A2+/B-level claim', () {
      final result = PlacementClassifier.classify([
        for (var i = 0; i <= 12; i++) MapEntry('A1-U$i', true),
      ]);
      expect(result.outcome, PlacementOutcome.a1Mastered);
      expect(result.recommendedUnitId, isNull);
    });

    test('every reachable outcome stays within the 4-value enum — the '
        'classifier has no code path that can express a B1+/B2+ result', () {
      expect(PlacementOutcome.values, hasLength(4));
    });

    test('stops at the FIRST failing unit even if scan continued past it — '
        'classification never looks past where evidence first weakens', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', true),
        const MapEntry('A1-U2', false),
        // A caller could still include entries after the first failure
        // (e.g. leftover data); classify() must not be swayed by them.
        const MapEntry('A1-U3', true),
      ]);
      expect(result.outcome, PlacementOutcome.startFromRecommendedUnit);
      expect(result.recommendedUnitId, 'A1-U2');
    });
  });
}
