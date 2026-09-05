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
  DateTime? mostRecentTimestamp;
  String? mostRecentUnitId;
  for (final progress in allLessonProgress) {
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
