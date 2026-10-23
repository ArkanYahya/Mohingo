import 'sync_records.dart';

/// The learner's account as the cloud holds it (`users/{uid}`).
class CloudAccount {
  const CloudAccount({required this.epoch, this.name, this.nameUpdatedAt});

  /// The account's progress generation — raised by "Reset progress" on any
  /// device. Records written under an older epoch are erased progress.
  final int epoch;
  final String? name;
  final DateTime? nameUpdatedAt;
}

/// Where a download stopped: the last document's server write time and id.
/// A cursor without [docId] means "everything written at or after
/// [serverUpdatedAt]".
class PullCursor {
  const PullCursor(this.serverUpdatedAt, [this.docId]);

  final DateTime serverUpdatedAt;
  final String? docId;

  /// A cursor [overlap] earlier, with no document id — re-reads a short
  /// window so a write that committed just behind the last one seen is
  /// never skipped. Re-reading is harmless: applying a record is idempotent.
  PullCursor rewound(Duration overlap) =>
      PullCursor(serverUpdatedAt.subtract(overlap));

  Map<String, Object?> toJson() => {
    'at': serverUpdatedAt.toUtc().microsecondsSinceEpoch,
    'id': docId,
  };

  static PullCursor? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = json['at'];
    if (at is! int) return null;
    return PullCursor(
      DateTime.fromMicrosecondsSinceEpoch(at, isUtc: true),
      json['id'] as String?,
    );
  }
}

/// One downloaded document, before schema validation.
class RemoteDoc {
  const RemoteDoc({
    required this.docId,
    required this.epoch,
    required this.fields,
    required this.cursor,
  });

  final String docId;
  final int epoch;
  final Map<String, Object?> fields;
  final PullCursor cursor;
}

/// Why a sync could not finish. Every cloud error is translated into one
/// of these by the store, so nothing above it sees a Firebase type.
enum SyncFailure {
  /// No network, or the service is unreachable: retry when back online.
  offline,

  /// The account's sign-in is no longer valid: the learner must sign in
  /// again.
  signedOut,

  /// The server refused access. Never expected for the learner's own data —
  /// a sign of misconfigured rules or a malformed record.
  permissionDenied,

  /// Anything else.
  unexpected,
}

class SyncException implements Exception {
  const SyncException(this.failure, [this.detail]);

  final SyncFailure failure;

  /// A developer-facing description — never shown to learners, never
  /// containing the learner's data.
  final String? detail;

  @override
  String toString() => 'SyncException(${failure.name}: $detail)';
}

/// Thrown when the account's epoch moved while a sync was running — another
/// device reset progress. The sync starts over, and applies the reset.
class StaleEpochException implements Exception {
  const StaleEpochException();
}

/// The learner's progress in the cloud: one account document and, under
/// it, one collection per [SyncCollection]. Implemented by
/// `FirestoreProgressStore`; tests use an in-memory one.
abstract interface class CloudProgressStore {
  /// The account document, or null if this account has never synced.
  Future<CloudAccount?> readAccount(String uid);

  /// Creates the account document if it is missing, and raises its epoch
  /// to [minEpoch] if it is lower. Returns the epoch it ends up with.
  Future<int> ensureAccount(String uid, {required int minEpoch});

  /// Records a progress reset: moves the account to a new epoch, higher
  /// than both its current one and [atLeast]. Returns the new epoch.
  Future<int> startNewEpoch(String uid, {required int atLeast});

  /// Sets the display name, unless the account holds a newer one.
  Future<void> putProfile(
    String uid, {
    required String? name,
    required DateTime updatedAt,
  });

  /// Uploads [records] under [epoch]. Append-only records are written as
  /// they are; the others are merged, on the server's side of a
  /// transaction, with the copy already there ([mergeRecords]), so a
  /// device's upload never erases what another device recorded. Throws
  /// [StaleEpochException] if a record's cloud copy belongs to a newer
  /// epoch.
  Future<void> putRecords(String uid, int epoch, List<SyncRecord> records);

  /// Up to [limit] documents of [collection] written after [after] (all of
  /// them when null), oldest first.
  Future<List<RemoteDoc>> pull(
    String uid,
    SyncCollection collection, {
    PullCursor? after,
    required int limit,
  });

  /// Deletes records left over from epochs before [epoch] — the progress a
  /// reset erased. Returns how many were deleted.
  Future<int> deleteRecordsBefore(String uid, int epoch);

  /// Deletes everything stored for [uid] — every record of every
  /// collection, then the account document — for "Delete account".
  Future<void> deleteAccount(String uid);
}
