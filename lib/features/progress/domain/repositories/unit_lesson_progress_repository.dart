import '../../../../data/local/database.dart';

/// The four unit-progress states — a recommendation, never a hard lock. See
/// docs/PRODUCT.md flow 5 and docs/DATA_MODEL.md.
enum UnitProgressState {
  notStarted,
  inProgress,
  needsReview,
  mastered;

  static UnitProgressState parse(String value) {
    return UnitProgressState.values.firstWhere((s) => s.name == value);
  }
}

/// Reads and writes the [UnitProgressData]/[LessonProgressData] read-models.
///
/// These are recomputed by [MasteryAggregationService] from
/// [ActivityAttemptRepository] evidence — never hand-edited by a UI action
/// directly. Only one implementation exists in v1
/// ([DriftUnitLessonProgressRepository]). See docs/DATA_MODEL.md.
abstract interface class UnitLessonProgressRepository {
  Future<UnitProgressData?> unitProgress({
    required int learnerId,
    required String unitId,
  });

  Future<List<UnitProgressData>> allUnitProgress({required int learnerId});

  /// Upserts the cached unit state — called only by
  /// [MasteryAggregationService], never directly by UI/application code.
  Future<void> upsertUnitProgress({
    required int learnerId,
    required String unitId,
    required UnitProgressState state,
    DateTime? masteredAt,
  });

  Future<LessonProgressData?> lessonProgress({
    required int learnerId,
    required String lessonId,
  });

  /// All lesson-progress rows for one learner within one unit — used to
  /// render per-lesson status on the unit overview without one query per
  /// lesson. See docs/superpowers/specs/
  /// 2026-09-04-ui-navigation-redesign-design.md.
  Future<List<LessonProgressData>> lessonProgressForUnit({
    required int learnerId,
    required String unitId,
  });

  /// Written after every meaningful lesson-player event (not just at lesson
  /// end) so the app can resume safely after being killed mid-lesson. See
  /// docs/DATA_MODEL.md.
  Future<void> recordLessonPosition({
    required int learnerId,
    required String lessonId,
    required String unitId,
    required String lastActivityId,
  });
}
