// Constructor params are named for their call sites (`local:`, `cloud:`);
// initializing formals would force the private field names into the API.
// ignore_for_file: prefer_initializing_formals

import 'dart:developer' as developer;

import 'cloud_progress_store.dart';
import 'local_progress_store.dart';
import 'sync_records.dart';

/// How a sync run ended.
enum SyncResult {
  succeeded,

  /// Offline or unreachable — nothing lost; the next run picks it up.
  deferred,
  failed,
}

class SyncOutcome {
  const SyncOutcome({
    required this.result,
    this.failure,
    this.uploaded = 0,
    this.downloaded = 0,
    this.localChanges = 0,
    this.evidenceChanged = false,
    this.remoteResetApplied = false,
  });

  final SyncResult result;
  final SyncFailure? failure;

  /// Records uploaded and downloaded this run.
  final int uploaded;
  final int downloaded;

  /// Local rows the download changed — non-zero means screens are stale.
  final int localChanges;

  /// Answers or test attempts arrived from another device, so unit mastery
  /// must be recomputed.
  final bool evidenceChanged;

  /// Another device reset progress, and this device followed.
  final bool remoteResetApplied;

  @override
  String toString() =>
      'SyncOutcome(${result.name}${failure == null ? '' : '/${failure!.name}'}, '
      'up $uploaded, down $downloaded, changed $localChanges'
      '${remoteResetApplied ? ', remote reset' : ''})';
}

/// A developer log line. Never given a password, token, email or answer —
/// only counts, collection names and a shortened account id.
typedef SyncLog = void Function(String message);

void _defaultLog(String message) =>
    developer.log(message, name: 'mohingo.sync');

/// One sync run for one learner: reconcile the epoch, upload what changed
/// here, download what changed elsewhere.
///
/// The local database stays the source of truth throughout: nothing here
/// blocks a learning feature, and an interrupted run loses nothing — the
/// outbox is only acknowledged after the cloud accepted an upload, and
/// download cursors only advance past records already applied. See
/// docs/adr/0010-optional-accounts-and-progress-sync.md.
class SyncEngine {
  SyncEngine({
    required LocalProgressStore local,
    required CloudProgressStore cloud,
    SyncLog? log,
    DateTime Function()? clock,
  }) : _local = local,
       _cloud = cloud,
       _log = log ?? _defaultLog,
       _clock = clock ?? DateTime.now;

  final LocalProgressStore _local;
  final CloudProgressStore _cloud;
  final SyncLog _log;
  final DateTime Function() _clock;

  static const uploadBatchSize = 200;
  static const downloadPageSize = 300;

  /// How far back each run re-reads, past its last cursor.
  static const cursorOverlap = Duration(minutes: 1);

  Future<SyncOutcome> sync({
    required int learnerId,
    required String firebaseUid,
  }) async {
    final who = 'account ${_shortId(firebaseUid)}';
    for (var attempt = 0; ; attempt++) {
      try {
        final outcome = await _run(learnerId, firebaseUid);
        _log('sync $who: $outcome');
        return outcome;
      } on StaleEpochException {
        if (attempt > 0) {
          _log('sync $who: epoch kept moving; giving up this run');
          return const SyncOutcome(
            result: SyncResult.failed,
            failure: SyncFailure.unexpected,
          );
        }
        _log('sync $who: another device reset progress mid-run; restarting');
      } on SyncException catch (e) {
        final deferred = e.failure == SyncFailure.offline;
        _log(
          'sync $who: ${deferred ? 'deferred' : 'failed'} '
          '(${e.failure.name}${e.detail == null ? '' : ': ${e.detail}'})',
        );
        return SyncOutcome(
          result: deferred ? SyncResult.deferred : SyncResult.failed,
          failure: e.failure,
        );
      }
    }
  }

  Future<SyncOutcome> _run(int learnerId, String uid) async {
    var state = await _local.syncState(learnerId, uid);
    final account = await _cloud.readAccount(uid);

    // 1. Agree on the epoch.
    var remoteResetApplied = false;
    var cleanUpOldEpochs = false;
    final recordingReset = state.resetPending;
    final int epoch;
    if (state.resetPending) {
      epoch = await _cloud.startNewEpoch(uid, atLeast: (state.epoch ?? 0) + 1);
      state = SyncState(firebaseUid: uid, epoch: epoch);
      cleanUpOldEpochs = true;
      _log('reset recorded on the account (epoch $epoch)');
    } else if (account == null || state.epoch == null) {
      epoch = await _cloud.ensureAccount(uid, minEpoch: state.epoch ?? 0);
      state = state.copyWith(epoch: epoch);
    } else if (account.epoch > state.epoch!) {
      // Another device reset progress. Everything recorded here under the
      // old epoch was erased by that reset — including anything not yet
      // uploaded — so this device follows it rather than resurrecting it.
      await _local.wipeProgress(learnerId);
      epoch = account.epoch;
      state = SyncState(firebaseUid: uid, epoch: epoch);
      remoteResetApplied = true;
      _log('conflict: account was reset elsewhere (epoch $epoch); followed');
    } else if (account.epoch < state.epoch!) {
      epoch = await _cloud.ensureAccount(uid, minEpoch: state.epoch!);
    } else {
      epoch = account.epoch;
    }
    await _local.saveSyncState(learnerId, state, clearsReset: recordingReset);

    var localChanges = 0;
    if (account?.nameUpdatedAt case final updatedAt?) {
      if (await _local.applyRemoteProfile(
        learnerId,
        name: account!.name,
        updatedAt: updatedAt,
      )) {
        localChanges++;
      }
    }

    // 2. Upload. The outbox entries go only once the cloud has the records.
    var uploaded = 0;
    while (true) {
      final pending = await _local.pendingUploads(
        learnerId,
        limit: uploadBatchSize,
      );
      if (pending.isEmpty) break;
      if (pending.profileUpdatedAt case final updatedAt?) {
        await _cloud.putProfile(
          uid,
          name: pending.profileName,
          updatedAt: updatedAt,
        );
      }
      if (pending.records.isNotEmpty) {
        await _cloud.putRecords(uid, epoch, pending.records);
      }
      await _local.acknowledgeUploads(pending.outboxIds);
      uploaded += pending.records.length;
    }

    // 3. Download what changed since the last run, collection by
    // collection, saving the cursor after every page.
    var downloaded = 0;
    var evidenceChanged = false;
    final cursors = Map.of(state.cursors);
    for (final collection in SyncCollection.values) {
      var after = cursors[collection]?.rewound(cursorOverlap);
      while (true) {
        final docs = await _cloud.pull(
          uid,
          collection,
          after: after,
          limit: downloadPageSize,
        );
        final records = <SyncRecord>[];
        for (final doc in docs) {
          if (doc.epoch > epoch) throw const StaleEpochException();
          if (doc.epoch < epoch) continue; // erased by a reset
          final record = SyncRecord.tryParse(collection, doc.docId, doc.fields);
          if (record == null) {
            _log('skipped a malformed ${collection.path} record');
            continue;
          }
          records.add(record);
        }
        final changed = await _local.applyRemote(
          learnerId,
          records,
          epoch: epoch,
        );
        downloaded += records.length;
        localChanges += changed;
        if (changed > 0 &&
            (collection == SyncCollection.attempts ||
                collection == SyncCollection.testAttempts)) {
          evidenceChanged = true;
        }
        if (docs.isEmpty) break;
        after = cursors[collection] = docs.last.cursor;
        state = state.copyWith(cursors: cursors);
        await _local.saveSyncState(learnerId, state);
        if (docs.length < downloadPageSize) break;
      }
    }

    state = state.copyWith(lastSyncedAt: _clock());
    await _local.saveSyncState(learnerId, state);

    if (cleanUpOldEpochs) {
      // Best effort: leftovers are ignored by every device anyway, and the
      // next reset's clean-up catches anything missed here.
      try {
        final deleted = await _cloud.deleteRecordsBefore(uid, epoch);
        _log('removed $deleted records erased by the reset');
      } on SyncException catch (e) {
        _log('clean-up after reset postponed (${e.failure.name})');
      }
    }

    return SyncOutcome(
      result: SyncResult.succeeded,
      uploaded: uploaded,
      downloaded: downloaded,
      localChanges: localChanges,
      evidenceChanged: evidenceChanged || remoteResetApplied,
      remoteResetApplied: remoteResetApplied,
    );
  }
}

/// Enough of an account id to tell accounts apart in a log, not enough to
/// identify one.
String _shortId(String uid) =>
    uid.length <= 4 ? uid : '${uid.substring(0, 4)}…';
