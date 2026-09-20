import '../../../content/catalog/level_catalog.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../data/local/database.dart';

/// Whether a learner can open a level right now, and if not, why.
enum LevelAccess {
  /// Lessons open normally.
  open,

  /// Released, but the learner hasn't reached it: they can finish the level
  /// it builds on, take the placement test, or open it anyway. A
  /// recommendation, never a wall — see docs/PRODUCT.md flow 5.
  lockedNeedsPrerequisite,

  /// The app hasn't released this level yet: its content is here to look
  /// at, its lessons don't open, and nothing the learner does changes that.
  notReleased,

  /// No content at all — the "coming later" levels.
  noContent,
}

/// The level the learner is working in: the one they selected most
/// recently, or the base level when they have never chosen one.
///
/// An enrolment written before levels were tracked has no `levelId` and
/// reads as the base level, which is the only level that existed then.
String currentLevelIdFor({
  required List<CourseEnrolment> enrolments,
  required List<LevelCatalogEntry> catalog,
}) {
  final known = {for (final entry in catalog) entry.levelId};
  CourseEnrolment? latest;
  for (final enrolment in enrolments) {
    final levelId = enrolment.levelId ?? kBaseLevelId;
    if (!known.contains(levelId)) continue;
    if (enrolment.lastSelectedAt == null) continue;
    if (latest == null ||
        enrolment.lastSelectedAt!.isAfter(latest.lastSelectedAt!)) {
      latest = enrolment;
    }
  }
  return latest?.levelId ?? kBaseLevelId;
}

/// Whether a level's own units are all mastered — every unit that counts
/// towards the level (a starter unit doesn't). A level with no units is
/// never complete.
bool levelComplete({
  required List<Unit> units,
  required Set<String> masteredUnitIds,
}) {
  final counting = units.where((u) => u.countsTowardLevelMastery).toList();
  if (counting.isEmpty) return false;
  return counting.every((u) => masteredUnitIds.contains(u.id));
}

/// Whether [entry] is open for a learner, given their [enrolment] in it and
/// whether they finished the level it builds on.
LevelAccess levelAccessFor({
  required LevelCatalogEntry entry,
  required CourseEnrolment? enrolment,
  required bool prerequisiteComplete,
}) {
  switch (entry.availability) {
    case LevelAvailability.comingSoon:
      return LevelAccess.noContent;
    case LevelAvailability.preview:
      return LevelAccess.notReleased;
    case LevelAvailability.available:
      if (entry.prerequisiteLevelId == null) return LevelAccess.open;
      if (prerequisiteComplete) return LevelAccess.open;
      if (enrolment?.unlockedAt != null) return LevelAccess.open;
      return LevelAccess.lockedNeedsPrerequisite;
  }
}
