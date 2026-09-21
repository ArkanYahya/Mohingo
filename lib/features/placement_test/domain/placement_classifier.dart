import 'placement_outcome.dart';

/// The pass rules the scan is built on, shared by [PlacementItemSampler]
/// callers and [PlacementClassifier].
///
/// [unitPassed] requires at least [minimumSampleSize] items before a unit
/// can fail — the concrete mechanism behind "never auto-skip a whole unit
/// from one multiple-choice answer": only a unit where enough items were
/// actually sampled and most of them missed can fail. A unit with too few
/// eligible items to judge is treated as passed (insufficient evidence
/// blocks nothing) rather than stalling the scan.
///
/// [blockPassed] has no such floor, and doesn't need one: a failed block
/// recommends nothing by itself — it only opens its units up to the
/// per-unit rule above, which is where the recommendation comes from.
abstract final class PlacementScoring {
  static const double minimumScoreRatio = 0.6;
  static const int minimumSampleSize = 2;

  static bool unitPassed(List<bool> itemCorrectness) {
    if (itemCorrectness.length < minimumSampleSize) return true;
    return _ratioMet(itemCorrectness);
  }

  /// One item per unit in the block; the block passes at the same 60%
  /// (two of three, three of four). An empty block — a level whose units
  /// yielded no eligible item — passes, like a unit with no evidence.
  static bool blockPassed(List<bool> itemCorrectness) {
    if (itemCorrectness.isEmpty) return true;
    return _ratioMet(itemCorrectness);
  }

  static bool _ratioMet(List<bool> itemCorrectness) {
    final correct = itemCorrectness.where((c) => c).length;
    return correct / itemCorrectness.length >= minimumScoreRatio;
  }
}

/// Turns a scan's per-unit results into one actionable
/// [PlacementClassification].
///
/// The scan itself is two-speed (Design 4): a block of 3–4 units is passed
/// or failed on one item each, and only a failed block is opened up unit by
/// unit. Only those unit-by-unit results reach this classifier, in order —
/// the first that failed *is* the recommended starting point, and a scan
/// that never opened a block never recommends anything from inside it.
abstract final class PlacementClassifier {
  /// [unitResultsInOrder] must be in curriculum order (A1-U0 first,
  /// A2-U12 last) and should stop at the first failing unit (the caller
  /// doesn't need to keep sampling past it).
  ///
  /// [topLevelId] is the highest released level, and the only level a
  /// "mastered" result may name.
  static PlacementClassification classify(
    List<MapEntry<String, bool>> unitResultsInOrder, {
    required String topLevelId,
  }) {
    for (final entry in unitResultsInOrder) {
      if (entry.value) continue;
      final outcome = switch (entry.key) {
        'A1-U0' => PlacementOutcome.startWithEssentials,
        'A1-U1' => PlacementOutcome.startA1FromU1,
        _ => PlacementOutcome.startFromRecommendedUnit,
      };
      return PlacementClassification(
        outcome: outcome,
        recommendedUnitId: entry.key,
      );
    }
    return PlacementClassification(
      outcome: PlacementOutcome.levelMastered,
      masteredLevelId: topLevelId,
    );
  }
}
