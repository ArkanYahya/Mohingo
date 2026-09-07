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

  /// Records that [learnerId] has started [courseId] at [contentVersion].
  /// Idempotent: calling this again for a course the learner is already
  /// enrolled in updates nothing.
  Future<void> ensureEnrolled({
    required int learnerId,
    required String courseId,
    required String contentVersion,
  });

  /// Sets [learnerId]'s display name — used by the `letterSequence`
  /// evaluator's `profileName` reference. Passing an empty string clears it
  /// back to unset.
  Future<void> updateName({required int learnerId, required String name});
}
