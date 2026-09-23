import '../../../../data/local/database.dart';

/// The learner profile and course-enrolment repository.
///
/// A device holds at most one guest learner plus one learner per account
/// that has signed in on it; exactly one is active, and every screen reads
/// the active one ([getOrCreateLearner]). Which one is active is decided by
/// `AccountSessionController`, through the account methods below. See
/// docs/adr/0010-optional-accounts-and-progress-sync.md.
abstract interface class LearnerRepository {
  /// Returns the active learner, creating a guest (with a fresh local UUID)
  /// if the device has no learner yet.
  Future<Learner> getOrCreateLearner();

  /// The learner with local id [learnerId].
  Future<Learner> learnerById(int learnerId);

  /// The learner bound to the account [firebaseUid] on this device, if that
  /// account has signed in here before.
  Future<Learner?> learnerForAccount(String firebaseUid);

  /// The guest learner (bound to no account), if the device has one.
  Future<Learner?> guestLearner();

  /// Makes the guest the active learner, creating a fresh guest if the
  /// device has none. Used on sign-out.
  Future<Learner> activateGuest();

  /// Makes [learnerId] the one active learner.
  Future<void> activate(int learnerId);

  /// Creates a learner owned by [firebaseUid] and makes it active.
  Future<Learner> createAccountLearner(String firebaseUid);

  /// Hands the guest [learnerId] — and with it all its progress — to the
  /// account [firebaseUid], and makes it active. The device is left without
  /// a guest until one is next needed.
  Future<Learner> bindGuestToAccount({
    required int learnerId,
    required String firebaseUid,
  });

  /// Whether [learnerId] has any progress worth keeping: an answer, a lesson
  /// position, a review state or a test attempt. An enrolment alone does not
  /// count — the app creates one on first launch.
  Future<bool> hasProgress(int learnerId);

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
