/// The A1 Gateway Placement Test's four actionable outcomes — deliberately
/// exhaustive and A1-only. The test must never fabricate a B1/B2+ result;
/// "the learner already knows this content" tops out at [a1Mastered], which
/// only ever recommends higher-level placement as a future feature, never
/// claims to have measured it. See docs/PRODUCT.md and docs/DATA_MODEL.md.
enum PlacementOutcome {
  /// Foundation gaps found at A1-U0 itself — recommend starting there.
  startWithEssentials,

  /// A1-U0 is solid but gaps begin immediately at A1-U1 — recommend
  /// starting regular A1 content from the beginning.
  startA1FromU1,

  /// Solid through some number of early A1 units, then a gap — recommend
  /// starting from the specific unit where evidence first weakens, never
  /// auto-skipping based on a single item.
  startFromRecommendedUnit,

  /// No gap found anywhere in A1 — A1 appears mastered; the app has no
  /// A2+ content to place into yet.
  a1Mastered,
}

/// The result of one placement scan: an [outcome] plus, when applicable,
/// the specific unit id it recommends starting from.
class PlacementClassification {
  const PlacementClassification({
    required this.outcome,
    this.recommendedUnitId,
  });

  final PlacementOutcome outcome;

  /// Set for [PlacementOutcome.startWithEssentials] (`"A1-U0"`),
  /// [PlacementOutcome.startA1FromU1] (`"A1-U1"`), and
  /// [PlacementOutcome.startFromRecommendedUnit] (the first unit that
  /// failed). Null only for [PlacementOutcome.a1Mastered].
  final String? recommendedUnitId;
}
