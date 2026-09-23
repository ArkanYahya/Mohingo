import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cloud_progress_store.dart';
import '../domain/sync_merge.dart';
import '../domain/sync_records.dart';

/// [CloudProgressStore] over Cloud Firestore — the only file in the sync
/// feature that touches a Firebase type.
///
/// Layout (docs/API_CONTRACT.md): `users/{uid}` holds the epoch and name;
/// `users/{uid}/{collection}/{docId}` holds one record, plus `epoch`,
/// `serverUpdatedAt` (a server timestamp — the download cursor) and `v`
/// (the record schema version). `firestore.rules` admits only the owner and
/// only this shape.
///
/// Built on a Firestore instance with local persistence *off*: the Drift
/// database is already the offline store, so a second cache would only
/// hide from the engine whether an upload really reached the server.
class FirestoreProgressStore implements CloudProgressStore {
  FirestoreProgressStore(this._db);

  final FirebaseFirestore _db;

  static const schemaVersion = 1;

  /// How long one request may take before the device is treated as offline.
  static const _timeout = Duration(seconds: 20);

  /// Transactions read every document they merge; kept well below
  /// Firestore's 500-write limit.
  static const _transactionSize = 100;
  static const _batchSize = 400;

  DocumentReference<Map<String, dynamic>> _account(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    SyncCollection collection,
  ) => _account(uid).collection(collection.path);

  @override
  Future<CloudAccount?> readAccount(String uid) => _guard(() async {
    final snapshot = await _account(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return CloudAccount(
      epoch: (data['epoch'] as num?)?.toInt() ?? 0,
      name: data['name'] as String?,
      nameUpdatedAt: _fromCloud(data['nameUpdatedAt']) as DateTime?,
    );
  });

  @override
  Future<int> ensureAccount(String uid, {required int minEpoch}) => _guard(() {
    return _db.runTransaction((tx) async {
      final ref = _account(uid);
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null) {
        tx.set(ref, _newAccount(minEpoch));
        return minEpoch;
      }
      final current = (data['epoch'] as num?)?.toInt() ?? 0;
      if (current >= minEpoch) return current;
      tx.update(ref, {
        'epoch': minEpoch,
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      });
      return minEpoch;
    });
  });

  @override
  Future<int> startNewEpoch(String uid, {required int atLeast}) => _guard(() {
    return _db.runTransaction((tx) async {
      final ref = _account(uid);
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      final current = (data?['epoch'] as num?)?.toInt() ?? 0;
      final next = current + 1 > atLeast ? current + 1 : atLeast;
      if (data == null) {
        tx.set(ref, _newAccount(next));
      } else {
        tx.update(ref, {
          'epoch': next,
          'serverUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      return next;
    });
  });

  Map<String, Object?> _newAccount(int epoch) => {
    'epoch': epoch,
    'name': null,
    'nameUpdatedAt': null,
    'createdAt': FieldValue.serverTimestamp(),
    'serverUpdatedAt': FieldValue.serverTimestamp(),
    'v': schemaVersion,
  };

  @override
  Future<void> putProfile(
    String uid, {
    required String? name,
    required DateTime updatedAt,
  }) => _guard(() {
    return _db.runTransaction((tx) async {
      final ref = _account(uid);
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null) return; // created by the next sync's ensureAccount
      final current = _fromCloud(data['nameUpdatedAt']) as DateTime?;
      if (current != null && !current.isBefore(updatedAt)) return;
      tx.update(ref, {
        'name': name,
        'nameUpdatedAt': Timestamp.fromDate(updatedAt),
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  });

  @override
  Future<void> putRecords(String uid, int epoch, List<SyncRecord> records) =>
      _guard(() async {
        final appendOnly = [
          for (final r in records)
            if (r.collection.appendOnly) r,
        ];
        final mergeable = [
          for (final r in records)
            if (!r.collection.appendOnly) r,
        ];

        // Records that never change: writing one again (a retried upload)
        // rewrites identical content, which the rules allow and nothing
        // downstream can tell apart.
        for (var i = 0; i < appendOnly.length; i += _batchSize) {
          final batch = _db.batch();
          for (final record in appendOnly.skip(i).take(_batchSize)) {
            batch.set(
              _collection(uid, record.collection).doc(record.docId),
              _toCloud(record, epoch),
            );
          }
          await batch.commit();
        }

        // Records that change: merged with the server's copy inside a
        // transaction, so two devices uploading at once both keep their
        // changes.
        for (var i = 0; i < mergeable.length; i += _transactionSize) {
          final chunk = mergeable.skip(i).take(_transactionSize).toList();
          await _db.runTransaction((tx) async {
            final refs = [
              for (final r in chunk)
                _collection(uid, r.collection).doc(r.docId),
            ];
            final snapshots = [for (final ref in refs) await tx.get(ref)];
            for (final (index, record) in chunk.indexed) {
              var toWrite = record;
              final data = snapshots[index].data();
              if (data != null) {
                final remoteEpoch = (data['epoch'] as num?)?.toInt() ?? 0;
                if (remoteEpoch > epoch) throw const StaleEpochException();
                final remote = remoteEpoch == epoch
                    ? SyncRecord.tryParse(
                        record.collection,
                        record.docId,
                        _fieldsFromCloud(data),
                      )
                    : null;
                if (remote != null) toWrite = mergeRecords(record, remote);
              }
              tx.set(refs[index], _toCloud(toWrite, epoch));
            }
          });
        }
      });

  @override
  Future<List<RemoteDoc>> pull(
    String uid,
    SyncCollection collection, {
    PullCursor? after,
    required int limit,
  }) => _guard(() async {
    Query<Map<String, dynamic>> query = _collection(
      uid,
      collection,
    ).orderBy('serverUpdatedAt').orderBy(FieldPath.documentId);
    if (after != null) {
      final at = Timestamp.fromDate(after.serverUpdatedAt);
      query = after.docId == null
          ? query.where('serverUpdatedAt', isGreaterThanOrEqualTo: at)
          : query.startAfter([at, after.docId]);
    }
    final snapshot = await query.limit(limit).get();
    return [
      for (final doc in snapshot.docs)
        if (doc.data()['serverUpdatedAt'] case final Timestamp at)
          RemoteDoc(
            docId: doc.id,
            epoch: (doc.data()['epoch'] as num?)?.toInt() ?? 0,
            fields: _fieldsFromCloud(doc.data()),
            cursor: PullCursor(at.toDate().toUtc(), doc.id),
          ),
    ];
  });

  @override
  Future<int> deleteRecordsBefore(String uid, int epoch) => _guard(() async {
    var deleted = 0;
    for (final collection in SyncCollection.values) {
      while (true) {
        final snapshot = await _collection(
          uid,
          collection,
        ).where('epoch', isLessThan: epoch).limit(_batchSize).get();
        if (snapshot.docs.isEmpty) break;
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        deleted += snapshot.docs.length;
      }
    }
    return deleted;
  });

  @override
  Future<void> deleteAccount(String uid) => _guard(() async {
    for (final collection in SyncCollection.values) {
      while (true) {
        final snapshot = await _collection(
          uid,
          collection,
        ).limit(_batchSize).get();
        if (snapshot.docs.isEmpty) break;
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await _account(uid).delete();
  });

  Map<String, Object?> _toCloud(SyncRecord record, int epoch) => {
    for (final MapEntry(:key, :value) in record.fields.entries)
      key: value is DateTime ? Timestamp.fromDate(value) : value,
    'epoch': epoch,
    'serverUpdatedAt': FieldValue.serverTimestamp(),
    'v': schemaVersion,
  };

  Map<String, Object?> _fieldsFromCloud(Map<String, dynamic> data) => {
    for (final MapEntry(:key, :value) in data.entries) key: _fromCloud(value),
  };

  Object? _fromCloud(Object? value) =>
      value is Timestamp ? value.toDate().toUtc() : value;

  /// Runs [body], translating every Firebase error into a [SyncException].
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on StaleEpochException {
      rethrow;
    } on TimeoutException {
      throw const SyncException(SyncFailure.offline, 'timed out');
    } on FirebaseException catch (e) {
      throw SyncException(switch (e.code) {
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' => SyncFailure.offline,
        'unauthenticated' => SyncFailure.signedOut,
        'permission-denied' => SyncFailure.permissionDenied,
        _ => SyncFailure.unexpected,
      }, e.code);
    }
  }
}
