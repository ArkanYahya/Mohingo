import 'package:mohingo/features/sync/domain/cloud_progress_store.dart';
import 'package:mohingo/features/sync/domain/sync_merge.dart';
import 'package:mohingo/features/sync/domain/sync_records.dart';

/// An in-memory [CloudProgressStore] with the Firestore store's semantics:
/// a server clock that stamps every write, append-only records written
/// as-is, mergeable records merged with the stored copy, the epoch rules,
/// and cursor-ordered downloads. Several "devices" share one instance.
///
/// [online] = false makes every call fail as offline; [failAfterCalls]
/// fails the Nth call from now, to test a run interrupted part-way.
class FakeCloudProgressStore implements CloudProgressStore {
  final Map<String, _Account> _accounts = {};
  DateTime _clock = DateTime.utc(2026, 9, 23, 12);

  bool online = true;
  int? failAfterCalls;
  int reads = 0;

  /// The raw documents of [uid]'s [collection], keyed by id.
  Map<String, Map<String, Object?>> docs(
    String uid,
    SyncCollection collection,
  ) => {
    for (final MapEntry(:key, :value)
        in (_accounts[uid]?.collections[collection] ?? {}).entries)
      key: {...value.fields, 'epoch': value.epoch},
  };

  int? epochOf(String uid) => _accounts[uid]?.epoch;

  /// Writes a raw document, bypassing validation — for malformed-data tests.
  void putRaw(
    String uid,
    SyncCollection collection,
    String docId,
    Map<String, Object?> fields, {
    int? epoch,
  }) {
    final account = _accounts.putIfAbsent(uid, _Account.new);
    account.collections.putIfAbsent(collection, () => {})[docId] = _Doc(
      fields,
      epoch ?? account.epoch,
      _tick(),
    );
  }

  DateTime _tick() => _clock = _clock.add(const Duration(milliseconds: 1));

  void _call() {
    if (!online) throw const SyncException(SyncFailure.offline, 'fake');
    if (failAfterCalls case final n?) {
      if (n <= 0) {
        failAfterCalls = null;
        throw const SyncException(SyncFailure.offline, 'fake interruption');
      }
      failAfterCalls = n - 1;
    }
  }

  @override
  Future<CloudAccount?> readAccount(String uid) async {
    _call();
    reads++;
    final account = _accounts[uid];
    if (account == null || !account.exists) return null;
    return CloudAccount(
      epoch: account.epoch,
      name: account.name,
      nameUpdatedAt: account.nameUpdatedAt,
    );
  }

  @override
  Future<int> ensureAccount(String uid, {required int minEpoch}) async {
    _call();
    final account = _accounts.putIfAbsent(uid, _Account.new);
    if (!account.exists) {
      account
        ..exists = true
        ..epoch = minEpoch;
    } else if (account.epoch < minEpoch) {
      account.epoch = minEpoch;
    }
    return account.epoch;
  }

  @override
  Future<int> startNewEpoch(String uid, {required int atLeast}) async {
    _call();
    final account = _accounts.putIfAbsent(uid, _Account.new);
    final next = account.epoch + 1 > atLeast ? account.epoch + 1 : atLeast;
    account
      ..exists = true
      ..epoch = next;
    return next;
  }

  @override
  Future<void> putProfile(
    String uid, {
    required String? name,
    required DateTime updatedAt,
  }) async {
    _call();
    final account = _accounts[uid];
    if (account == null || !account.exists) return;
    final current = account.nameUpdatedAt;
    if (current != null && !current.isBefore(updatedAt)) return;
    account
      ..name = name
      ..nameUpdatedAt = updatedAt;
  }

  @override
  Future<void> putRecords(
    String uid,
    int epoch,
    List<SyncRecord> records,
  ) async {
    _call();
    final account = _accounts.putIfAbsent(uid, _Account.new);
    // Checked before writing anything, like a failed transaction.
    for (final record in records) {
      final existing = account.collections[record.collection]?[record.docId];
      if (!record.collection.appendOnly &&
          existing != null &&
          existing.epoch > epoch) {
        throw const StaleEpochException();
      }
    }
    for (final record in records) {
      final docs = account.collections.putIfAbsent(record.collection, () => {});
      var toWrite = record;
      final existing = docs[record.docId];
      if (!record.collection.appendOnly &&
          existing != null &&
          existing.epoch == epoch) {
        final remote = SyncRecord.tryParse(
          record.collection,
          record.docId,
          existing.fields,
        );
        if (remote != null) toWrite = mergeRecords(record, remote);
      }
      docs[record.docId] = _Doc(Map.of(toWrite.fields), epoch, _tick());
    }
  }

  @override
  Future<List<RemoteDoc>> pull(
    String uid,
    SyncCollection collection, {
    PullCursor? after,
    required int limit,
  }) async {
    _call();
    final entries =
        (_accounts[uid]?.collections[collection] ?? {}).entries.toList()
          ..sort((a, b) {
            final byTime = a.value.at.compareTo(b.value.at);
            return byTime != 0 ? byTime : a.key.compareTo(b.key);
          });
    final result = <RemoteDoc>[];
    for (final MapEntry(key: id, value: doc) in entries) {
      if (after != null) {
        final order = doc.at.compareTo(after.serverUpdatedAt);
        if (after.docId == null) {
          if (order < 0) continue;
        } else if (order < 0 ||
            (order == 0 && id.compareTo(after.docId!) <= 0)) {
          continue;
        }
      }
      result.add(
        RemoteDoc(
          docId: id,
          epoch: doc.epoch,
          fields: Map.of(doc.fields),
          cursor: PullCursor(doc.at, id),
        ),
      );
      if (result.length == limit) break;
    }
    reads += result.isEmpty ? 1 : result.length;
    return result;
  }

  @override
  Future<int> deleteRecordsBefore(String uid, int epoch) async {
    _call();
    var deleted = 0;
    for (final docs
        in _accounts[uid]?.collections.values ?? <Map<String, _Doc>>[]) {
      final stale = [
        for (final MapEntry(:key, :value) in docs.entries)
          if (value.epoch < epoch) key,
      ];
      stale.forEach(docs.remove);
      deleted += stale.length;
    }
    return deleted;
  }

  final deletedAccounts = <String>[];

  @override
  Future<void> deleteAccount(String uid) async {
    _call();
    _accounts.remove(uid);
    deletedAccounts.add(uid);
  }

  /// Whether anything is stored for [uid].
  bool hasAccount(String uid) => _accounts.containsKey(uid);
}

class _Account {
  bool exists = false;
  int epoch = 0;
  String? name;
  DateTime? nameUpdatedAt;
  final Map<SyncCollection, Map<String, _Doc>> collections = {};
}

class _Doc {
  _Doc(this.fields, this.epoch, this.at);

  final Map<String, Object?> fields;
  final int epoch;
  final DateTime at;
}
