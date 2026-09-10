/// The 3 "tasks today" the Home screen tracks — see
/// [DailyTaskEventRepository] and docs/DATA_MODEL.md.
enum DailyTaskType {
  lesson,
  vocabularyReview,
  speaking;

  static DailyTaskType parse(String value) {
    return DailyTaskType.values.firstWhere((t) => t.name == value);
  }
}

/// Today's count for each [DailyTaskType], for Home's "Tasks today" row.
typedef DailyTaskCounts = ({int lesson, int vocabularyReview, int speaking});

/// Records and counts the moments that back Home's "Tasks today" row: a
/// lesson finishing, a vocabulary word being reviewed, or a speaking
/// activity being submitted. Insert-only, like [ActivityAttemptRepository]
/// — never overwritten or deduplicated at write time.
///
/// Only one implementation exists in v1 ([DriftDailyTaskEventRepository]);
/// written as an interface so a future sync implementation can be swapped
/// in via provider override without touching callers. See
/// docs/DATA_MODEL.md and docs/ARCHITECTURE.md.
abstract interface class DailyTaskEventRepository {
  /// Records one [taskType] event for [learnerId], at [occurredAt] (defaults
  /// to now).
  Future<void> recordEvent({
    required int learnerId,
    required DailyTaskType taskType,
    DateTime? occurredAt,
  });

  /// Counts each [DailyTaskType]'s events on [asOf]'s calendar date
  /// (inclusive), for [learnerId]. Same local-day convention as
  /// [ActivityAttemptRepository.currentStreakDays] — no UTC normalization.
  Future<DailyTaskCounts> countsForToday({
    required int learnerId,
    required DateTime asOf,
  });
}
