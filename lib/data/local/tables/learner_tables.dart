import 'package:drift/drift.dart';

/// A single local learner profile.
///
/// v1 auto-creates exactly one row on first launch and never exposes profile
/// switching; kept as a real table (not a single-row preferences blob) so a
/// future multi-profile or sync-merge scenario needs no schema change.
/// Identity is a locally-generated [uuid], never a Firebase Auth UID — see
/// docs/adr/0004-local-only-v1-no-firebase-backend.md.
class Learners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get nativeLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get targetLanguage => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
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
