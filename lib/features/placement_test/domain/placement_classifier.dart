import 'placement_outcome.dart';

/// Per-unit pass/fail rule shared by [PlacementItemSampler] callers and
/// [PlacementClassifier].
///
/// Requires at least [minimumSampleSize] items before a unit can fail —
/// this is the concrete mechanism behind "never auto-skip a whole unit from
/// one multiple-choice answer": a single wrong answer can never fail a
/// unit, only a unit where enough items were actually sampled and most of
/// them missed. A unit with too few eligible items to judge is treated as
/// passed (insufficient evidence blocks nothing) rather than stalling the
/// scan.
abstract final class PlacementScoring {
  static const double minimumScoreRatio = 0.6;
  static const int minimumSampleSize = 2;

  static bool unitPassed(List<bool> itemCorrectness) {
    if (itemCorrectness.length < minimumSampleSize) return true;
    final correct = itemCorrectness.where((c) => c).length;
    return correct / itemCorrectness.length >= minimumScoreRatio;
  }
}

/// Turns an ordered scan of per-unit pass/fail results into one of the four
/// actionable [PlacementOutcome]s.
///
/// This collapses the master prompt's "Stage 1 foundation check (U0-U3) +
/// Stage 2 adaptive receptive check (U4-U12)" into a single continuous
/// unit-by-unit scan in bundle order, stopping at the first unit that
/// fails: the first failing unit *is* the recommended starting point, so
/// there is nothing more useful an adaptive stage boundary would add, and
/// stopping there is exactly the "stop early once evidence is sufficient"
/// behavior the master prompt asks for — see
/// docs/adr/ (Phase 9 note) and the Phase 9 report.
abstract final class PlacementClassifier {
  /// [unitResultsInOrder] must already be in curriculum order (A1-U0
  /// first) and should stop at the first failing unit (the caller doesn't
  /// need to keep sampling past it).
  static PlacementClassification classify(
    List<MapEntry<String, bool>> unitResultsInOrder,
  ) {
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
    return const PlacementClassification(outcome: PlacementOutcome.a1Mastered);
  }
}
