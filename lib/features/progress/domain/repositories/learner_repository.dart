import '../../../../data/local/database.dart';

/// The learner profile and course-enrolment repository.
///
/// v1 has no multi-profile support and no accounts — see
/// docs/adr/0004-local-only-v1-no-firebase-backend.md — so
/// [getOrCreateLearner] always resolves to the same single local profile,
/// created on first call. Only one implementation exists in v1
/// ([DriftLearnerRepository]); the interface is written so a future
/// account-sync implementation can be swapped in via provider override
/// without touching callers. See docs/ARCHITECTURE.md.
abstract interface class LearnerRepository {
  /// Returns the single active learner, creating one (with a fresh local
  /// UUID — never a Firebase Auth UID) if none exists yet.
  Future<Learner> getOrCreateLearner();

  /// Records that [learnerId] has started the catalogue level [levelId]
  /// (bundle [courseId]) at [contentVersion]. Idempotent: a level the
  /// learner is already enrolled in keeps its original row — except that a
  /// row written before levels were tracked (null `levelId`) is backfilled
  /// with [levelId] rather than duplicated.
  Future<void> ensureEnrolled({
    required int learnerId,
    required String levelId,
    required String courseId,
    required String contentVersion,
  });

  /// Every level [learnerId] has started, in no particular order — the
  /// caller decides what "current" means (see
  /// `lib/features/progress/domain/level_access.dart`).
  Future<List<CourseEnrolment>> enrolments({required int learnerId});

  /// [learnerId]'s enrolment in [levelId], or null if they never started it.
  Future<CourseEnrolment?> enrolmentForLevel({
    required int learnerId,
    required String levelId,
  });

  /// Marks [levelId] as the level [learnerId] is working in now. A level
  /// they have never started is ignored — enrolment comes first.
  Future<void> markLevelSelected({
    required int learnerId,
    required String levelId,
    DateTime? at,
  });

  /// Records that [levelId] is open for [learnerId]. Idempotent: an
  /// already-open level keeps the time it first opened, so "when did this
  /// learner reach A2" stays answerable.
  Future<void> markLevelUnlocked({
    required int learnerId,
    required String levelId,
    DateTime? at,
  });

  /// Sets [learnerId]'s display name — used by the `letterSequence`
  /// evaluator's `profileName` reference. Passing an empty string clears it
  /// back to unset.
  Future<void> updateName({required int learnerId, required String name});
}
