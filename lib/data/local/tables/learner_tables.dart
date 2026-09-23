import 'package:drift/drift.dart';

/// A single local learner profile.
///
/// One row per *owner* of progress on this device: at most one guest (no
/// [firebaseUid]) plus one per account that has signed in here. Exactly one
/// row is [isActive] — the learner every screen reads. Signing out makes the
/// guest active again; the account's row stays on the device, invisible,
/// until that same account signs back in, so one account's progress can
/// never surface under another. [uuid] is the local identity; the account
/// identity is [firebaseUid]. See
/// docs/adr/0010-optional-accounts-and-progress-sync.md.
class Learners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get nativeLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get targetLanguage => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// The Firebase Auth UID this learner's progress belongs to; null for the
  /// guest. Unique: an account owns at most one learner row per device.
  TextColumn get firebaseUid => text().nullable().unique()();

  /// When [name] last changed — the last-writer-wins clock for syncing it.
  /// Null on rows written before schema v6 and on never-named learners.
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// One row per learner per curriculum bundle they've started.
///
/// Anchors "which content version was this progress recorded against" —
/// [contentVersion] is copied from the bundle's own `contentVersion` field at
/// enrolment time. See docs/DATA_MODEL.md.
class CourseEnrolments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get courseId => text()();
  TextColumn get contentVersion => text()();
  DateTimeColumn get enrolledAt => dateTime()();
  TextColumn get status => text()();

  /// The catalogue level this enrolment is for (`"a1"`, `"a2"`) — the same
  /// key `kLevelCatalog` and `courseContentProvider` use. Null on rows
  /// written before schema v5, which are read as the base level; see
  /// `LearnerRepository.ensureEnrolled`, which backfills them.
  TextColumn get levelId => text().nullable()();

  /// When the learner last made this level the one they're working in. The
  /// enrolment with the most recent value is the current level; null means
  /// they have never chosen it explicitly.
  DateTimeColumn get lastSelectedAt => dateTime().nullable()();

  /// When the learner chose to open this level before finishing the one it
  /// builds on — the lock sheet's "open anyway" (`LevelSelectionController.
  /// unlock`). Null otherwise: while it's still locked, and also once it's
  /// open because its prerequisite is complete, which needs no unlock row.
  /// See `lib/features/progress/domain/level_access.dart`.
  DateTimeColumn get unlockedAt => dateTime().nullable()();
}
