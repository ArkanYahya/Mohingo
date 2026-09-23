import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// One row per local write not yet uploaded to the learner's account.
///
/// Filled by SQLite triggers (see `AppDatabase.syncTriggerStatements`), not
/// by repository code: every insert or update of a synced table enqueues
/// `(entity, rowId)`, so a write path added later is synced without anyone
/// remembering to. The sync engine reads the current row at upload time —
/// several entries for one row collapse into one upload — and deletes the
/// entries once the upload is acknowledged. Guest rows sit here too, and are
/// uploaded if the guest's progress is later attached to an account. See
/// docs/adr/0010-optional-accounts-and-progress-sync.md.
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The SQL table name of the changed row (`activity_attempts`, ...).
  TextColumn get entity => text()();
  IntColumn get rowId => integer()();
  IntColumn get learnerId => integer()();
}

/// Per-learner sync bookkeeping for a learner bound to an account.
///
/// [epoch] is the account's progress generation: "Reset progress" starts a
/// new one on every device (null until the first sync has read the
/// account's). [resetPending] marks a reset made here that the account has
/// not heard about yet. [cursorsJson] holds, per cloud collection, the
/// position the last download reached, so a sync only fetches what changed.
class AccountSyncStates extends Table {
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get firebaseUid => text()();
  IntColumn get epoch => integer().nullable()();
  BoolColumn get resetPending => boolean().withDefault(const Constant(false))();
  TextColumn get cursorsJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {learnerId};
}
