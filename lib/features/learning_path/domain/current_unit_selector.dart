import '../../../content/models/curriculum_structure.dart';
import '../../../data/local/database.dart';

/// Picks which unit is the learner's current "you are here" position, for
/// the Learn spine and Home's "Continue" card.
///
/// Prefers the most recently active unit — by the latest
/// [LessonProgressData.lastPositionUpdatedAt] across all its lessons, which
/// updates on every single activity submission — as long as that unit
/// isn't fully mastered yet. This is what lets the position actually move
/// forward once a learner starts a new unit: units are always freely
/// tappable (no hard lock), so a learner can move on without perfectly
/// mastering every objective in the previous one, and "you are here"
/// should follow them rather than stay pinned to an imperfectly-finished
/// unit forever.
///
/// Only progress rows whose unit is in [units] — the level currently being
/// shown — count toward "most recently active": a learner can be enrolled
/// in more than one level at once, and a more recent timestamp from a unit
/// in a different level must not override where they are in this one.
///
/// Falls back to the first not-yet-mastered unit in curriculum order when
/// there's no recorded activity anywhere yet, or when the most recently
/// active unit is already fully mastered (advancing to the next thing to
/// do rather than lingering on finished work). Returns `null` when every
/// unit is mastered.
String? currentUnitId({
  required List<Unit> units,
  required Set<String> masteredUnitIds,
  required List<LessonProgressData> allLessonProgress,
}) {
  final unitIdsInLevel = {for (final unit in units) unit.id};
  DateTime? mostRecentTimestamp;
  String? mostRecentUnitId;
  for (final progress in allLessonProgress) {
    // A learner can have progress in more than one level. "Where you are"
    // is always a position inside the level being shown — a unit id from
    // another level resolves to nothing in this level's index, leaving
    // the Learn tab and Home with no current unit at all.
    if (!unitIdsInLevel.contains(progress.unitId)) continue;
    final updatedAt = progress.lastPositionUpdatedAt;
    if (updatedAt == null) continue;
    if (mostRecentTimestamp == null || updatedAt.isAfter(mostRecentTimestamp)) {
      mostRecentTimestamp = updatedAt;
      mostRecentUnitId = progress.unitId;
    }
  }

  if (mostRecentUnitId != null && !masteredUnitIds.contains(mostRecentUnitId)) {
    return mostRecentUnitId;
  }

  for (final unit in units) {
    if (!masteredUnitIds.contains(unit.id)) return unit.id;
  }
  return null;
}
