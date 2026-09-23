import 'cloud_progress_store.dart';
import 'sync_records.dart';

/// A learner's sync bookkeeping (the `account_sync_states` row).
class SyncState {
  const SyncState({
    required this.firebaseUid,
    this.epoch,
    this.resetPending = false,
    this.cursors = const {},
    this.lastSyncedAt,
  });

  final String firebaseUid;

  /// The account epoch the local progress belongs to; null until the first
  /// sync has read the account's.
  final int? epoch;

  /// A reset made on this device that the account hasn't recorded yet.
  final bool resetPending;
  final Map<SyncCollection, PullCursor> cursors;
  final DateTime? lastSyncedAt;

  SyncState copyWith({
    int? epoch,
    bool? resetPending,
    Map<SyncCollection, PullCursor>? cursors,
    DateTime? lastSyncedAt,
  }) => SyncState(
    firebaseUid: firebaseUid,
    epoch: epoch ?? this.epoch,
    resetPending: resetPending ?? this.resetPending,
    cursors: cursors ?? this.cursors,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}

/// Local writes waiting to be uploaded, read from the outbox.
class PendingUploads {
  const PendingUploads({
    required this.outboxIds,
    required this.records,
    this.profileName,
    this.profileUpdatedAt,
  });

  /// The outbox entries these uploads cover — acknowledged together once
  /// the upload succeeds.
  final List<int> outboxIds;
  final List<SyncRecord> records;

  /// The learner's name, when it changed (null [profileUpdatedAt] means
  /// the name isn't part of this upload).
  final String? profileName;
  final DateTime? profileUpdatedAt;

  bool get isEmpty => outboxIds.isEmpty;
}

/// The learner's side of the sync: the local database. Implemented by
/// `DriftLocalProgressStore`.
abstract interface class LocalProgressStore {
  /// [learnerId]'s sync state, created on first use. Throws [StateError] if
  /// the learner doesn't belong to [firebaseUid] — the guard that keeps one
  /// account's progress from ever being uploaded to another.
  Future<SyncState> syncState(int learnerId, String firebaseUid);

  /// Saves [state]. Throws [StaleEpochException] — saving nothing — if a
  /// reset was made here since the sync read the state, unless this save
  /// is the one recording that reset ([clearsReset]).
  Future<void> saveSyncState(
    int learnerId,
    SyncState state, {
    bool clearsReset = false,
  });

  /// Up to [limit] outbox entries for [learnerId], resolved into the
  /// records to upload (several entries for one row become one record).
  Future<PendingUploads> pendingUploads(int learnerId, {required int limit});

  Future<void> acknowledgeUploads(List<int> outboxIds);

  /// How many local writes are waiting to be uploaded.
  Future<int> pendingCount(int learnerId);

  /// Merges downloaded [records] of account epoch [epoch] into
  /// [learnerId]'s progress, without queueing them for upload again.
  /// Returns how many local rows changed. Throws [StaleEpochException] —
  /// applying nothing — if the learner's progress was reset since the sync
  /// read its state, so records from before a reset are never restored.
  Future<int> applyRemote(
    int learnerId,
    List<SyncRecord> records, {
    required int epoch,
  });

  /// Takes the account's name if it is newer than the local one. Returns
  /// whether it changed.
  Future<bool> applyRemoteProfile(
    int learnerId, {
    required String? name,
    required DateTime updatedAt,
  });

  /// Erases [learnerId]'s progress because another device reset it.
  Future<void> wipeProgress(int learnerId);
}
