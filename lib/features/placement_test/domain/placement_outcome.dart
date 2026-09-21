/// The placement test's four actionable outcomes.
///
/// Deliberately exhaustive: the test may never fabricate a level the app
/// has no content for. "The learner already knows this" tops out at
/// [levelMastered], which names the top *released* level and nothing
/// above it. See docs/PRODUCT.md, docs/DATA_MODEL.md and Design 4 of
/// docs/superpowers/specs/2026-09-19-a2-level-design.md.
enum PlacementOutcome {
  /// Foundation gaps found at A1-U0 itself — recommend starting there.
  startWithEssentials,

  /// A1-U0 is solid but gaps begin immediately at A1-U1 — recommend
  /// starting regular A1 content from the beginning.
  startA1FromU1,

  /// Solid through some number of earlier units, then a gap — recommend
  /// starting from the specific unit where evidence first weakens, in
  /// whichever released level that unit belongs to (the level is read off
  /// the unit id, which names it). Never auto-skips on a single item.
  startFromRecommendedUnit,

  /// No gap found anywhere in any released level — the top released level
  /// looks mastered. Stored per level (`a1Mastered`, `a2Mastered`, …) so a
  /// result recorded when A1 was the only level keeps saying A1 after A2
  /// ships; see [PlacementClassification.storedOutcome].
  levelMastered,
}

/// The result of one placement scan: an [outcome] plus the unit or level
/// it names.
class PlacementClassification {
  const PlacementClassification({
    required this.outcome,
    this.recommendedUnitId,
    this.masteredLevelId,
  });

  final PlacementOutcome outcome;

  /// Set for [PlacementOutcome.startWithEssentials] (`"A1-U0"`),
  /// [PlacementOutcome.startA1FromU1] (`"A1-U1"`), and
  /// [PlacementOutcome.startFromRecommendedUnit] (the first unit that
  /// failed, `"A1-U2"`…`"A2-U12"`). Null for
  /// [PlacementOutcome.levelMastered].
  final String? recommendedUnitId;

  /// The level that looks mastered — only for
  /// [PlacementOutcome.levelMastered], and never above the top released
  /// level.
  final String? masteredLevelId;

  /// What goes in `placement_attempts.outcome`.
  ///
  /// Every value but [PlacementOutcome.levelMastered] stores its own name,
  /// unchanged from before the test covered more than one level, so stored
  /// history stays readable. A mastered level stores `"<levelId>Mastered"`
  /// — which makes the `a1Mastered` rows written when A1 was the only
  /// level a member of the family rather than a legacy special case, and
  /// stops a past result being re-read as a claim about a level that
  /// shipped later.
  String get storedOutcome => outcome == PlacementOutcome.levelMastered
      ? '${masteredLevelId ?? ''}Mastered'
      : outcome.name;
}

final _masteredOutcome = RegExp(r'^([a-z][0-9])Mastered$');

/// The level id a stored `"<levelId>Mastered"` outcome names, or null when
/// [storedOutcome] is one of the unit-based outcomes.
///
/// Reads `a1Mastered` (written before the test covered A2) exactly as it
/// reads `a2Mastered`.
String? masteredLevelIdOfStoredOutcome(String storedOutcome) =>
    _masteredOutcome.firstMatch(storedOutcome)?.group(1);
