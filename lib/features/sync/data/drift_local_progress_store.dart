import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/cloud_progress_store.dart';
import '../domain/local_progress_store.dart';
import '../domain/sync_merge.dart';
import '../domain/sync_records.dart';

/// [LocalProgressStore] over the Drift database: turns outbox entries into
/// [SyncRecord]s, and merges downloaded records into the learner's rows.
///
/// Downloaded records are applied inside one transaction that also removes
/// the outbox entries the apply itself triggered — a record that came from
/// the account is never queued to go back up.
class DriftLocalProgressStore implements LocalProgressStore {
  DriftLocalProgressStore(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<SyncState> syncState(int learnerId, String firebaseUid) {
    return _db.transaction(() async {
      final learner = await (_db.select(
        _db.learners,
      )..where((t) => t.id.equals(learnerId))).getSingle();
      if (learner.firebaseUid != firebaseUid) {
        throw StateError('learner $learnerId does not belong to this account');
      }
      final row = await (_db.select(
        _db.accountSyncStates,
      )..where((t) => t.learnerId.equals(learnerId))).getSingleOrNull();
      if (row == null) {
        await _db
            .into(_db.accountSyncStates)
            .insert(
              AccountSyncStatesCompanion.insert(
                learnerId: Value(learnerId),
                firebaseUid: firebaseUid,
              ),
            );
        return SyncState(firebaseUid: firebaseUid);
      }
      if (row.firebaseUid != firebaseUid) {
        throw StateError('sync state of learner $learnerId has another owner');
      }
      return SyncState(
        firebaseUid: row.firebaseUid,
        epoch: row.epoch,
        resetPending: row.resetPending,
        cursors: _decodeCursors(row.cursorsJson),
        lastSyncedAt: row.lastSyncedAt,
      );
    });
  }

  @override
  Future<void> saveSyncState(
    int learnerId,
    SyncState state, {
    bool clearsReset = false,
  }) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.accountSyncStates,
      )..where((t) => t.learnerId.equals(learnerId))).getSingleOrNull();
      if (current != null && current.resetPending && !clearsReset) {
        throw const StaleEpochException();
      }
      await _db
          .into(_db.accountSyncStates)
          .insertOnConflictUpdate(
            AccountSyncStatesCompanion.insert(
              learnerId: Value(learnerId),
              firebaseUid: state.firebaseUid,
              epoch: Value(state.epoch),
              resetPending: Value(state.resetPending),
              cursorsJson: Value(
                jsonEncode({
                  for (final MapEntry(:key, :value) in state.cursors.entries)
                    key.path: value.toJson(),
                }),
              ),
              lastSyncedAt: Value(state.lastSyncedAt),
            ),
          );
    });
  }

  /// Erases [learnerId]'s progress and, when [firebaseUid] is set, marks
  /// the reset for upload: the next sync moves the account to a new epoch,
  /// which every other device follows. Both happen in one transaction, so a
  /// sync running alongside can't slip the erased records back in (see
  /// [applyRemote]); and the mark is recorded even if this learner has
  /// never synced, so a first sync can't bring the erased progress back.
  Future<void> resetProgress(int learnerId, {String? firebaseUid}) {
    return _db.transaction(() async {
      if (firebaseUid != null) await _markResetPending(learnerId, firebaseUid);
      await _db.resetProgressForLearner(learnerId);
    });
  }

  Future<void> _markResetPending(int learnerId, String firebaseUid) async {
    final existing = await (_db.select(
      _db.accountSyncStates,
    )..where((t) => t.learnerId.equals(learnerId))).getSingleOrNull();
    await _db
        .into(_db.accountSyncStates)
        .insertOnConflictUpdate(
          AccountSyncStatesCompanion.insert(
            learnerId: Value(learnerId),
            firebaseUid: firebaseUid,
            epoch: Value(existing?.epoch),
            resetPending: const Value(true),
            cursorsJson: const Value('{}'),
            lastSyncedAt: Value(existing?.lastSyncedAt),
          ),
        );
  }

  /// When [learnerId] last finished a sync, or null if it never has.
  Future<DateTime?> lastSyncedAt(int learnerId) async {
    final row = await (_db.select(
      _db.accountSyncStates,
    )..where((t) => t.learnerId.equals(learnerId))).getSingleOrNull();
    return row?.lastSyncedAt;
  }

  /// Emits whenever [learnerId]'s outbox changes — the signal that there
  /// is something new to upload.
  Stream<int> watchPendingCount(int learnerId) {
    final count = _db.syncOutbox.id.count();
    return (_db.selectOnly(_db.syncOutbox)
          ..addColumns([count])
          ..where(_db.syncOutbox.learnerId.equals(learnerId)))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  @override
  Future<int> pendingCount(int learnerId) => watchPendingCount(learnerId).first;

  @override
  Future<PendingUploads> pendingUploads(
    int learnerId, {
    required int limit,
  }) async {
    final entries =
        await (_db.select(_db.syncOutbox)
              ..where((t) => t.learnerId.equals(learnerId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(limit))
            .get();
    final idsByEntity = <String, Set<int>>{};
    for (final entry in entries) {
      idsByEntity.putIfAbsent(entry.entity, () => {}).add(entry.rowId);
    }

    final records = <SyncRecord>[];
    String? profileName;
    DateTime? profileUpdatedAt;
    for (final MapEntry(key: entity, value: ids) in idsByEntity.entries) {
      final rowIds = ids.toList();
      switch (entity) {
        case 'activity_attempts':
          final rows =
              await (_db.select(_db.activityAttempts)..where(
                    (t) => t.id.isIn(rowIds) & t.learnerId.equals(learnerId),
                  ))
                  .get();
          final canDos = await (_db.select(
            _db.activityAttemptCanDos,
          )..where((t) => t.attemptId.isIn(rowIds))).get();
          for (final row in rows) {
            records.add(
              _record(
                SyncCollection.attempts,
                attemptFields(row, [
                  for (final c in canDos)
                    if (c.attemptId == row.id) c.canDoId,
                ]),
              ),
            );
          }
        case 'lesson_progress':
          for (final row in await (_db.select(
            _db.lessonProgress,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.lessonProgress, lessonFields(row)),
            );
          }
        case 'vocabulary_review_state':
          for (final row in await (_db.select(
            _db.vocabularyReviewState,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            if (row.lexiconId == null && row.chunkId == null) continue;
            records.add(
              _record(SyncCollection.vocabularyReview, vocabularyFields(row)),
            );
          }
        case 'grammar_review_state':
          for (final row in await (_db.select(
            _db.grammarReviewState,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.grammarReview, grammarFields(row)),
            );
          }
        case 'course_enrolments':
          for (final row in await (_db.select(
            _db.courseEnrolments,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            // A pre-v5 row without a level is backfilled on next launch,
            // and that update queues it again.
            if (row.learnerId != learnerId || row.levelId == null) continue;
            records.add(
              _record(SyncCollection.enrolments, enrolmentFields(row)),
            );
          }
        case 'placement_attempts':
          for (final row in await (_db.select(
            _db.placementAttempts,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.testAttempts, placementFields(row)),
            );
          }
        case 'final_mission_attempts':
          for (final row in await (_db.select(
            _db.finalMissionAttempts,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.testAttempts, missionFields(row)),
            );
          }
        case 'final_assessment_attempts':
          for (final row in await (_db.select(
            _db.finalAssessmentAttempts,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.testAttempts, assessmentFields(row)),
            );
          }
        case 'daily_task_events':
          for (final row in await (_db.select(
            _db.dailyTaskEvents,
          )..where((t) => t.id.isIn(rowIds))).get()) {
            if (row.learnerId != learnerId) continue;
            records.add(
              _record(SyncCollection.dailyTasks, dailyTaskFields(row)),
            );
          }
        case 'learners':
          final learner = await (_db.select(
            _db.learners,
          )..where((t) => t.id.equals(learnerId))).getSingle();
          // A name set before schema v6 has no updatedAt; it dates from
          // no later than the learner row itself.
          profileName = learner.name;
          profileUpdatedAt = (learner.updatedAt ?? learner.createdAt).toUtc();
      }
    }
    return PendingUploads(
      outboxIds: [for (final e in entries) e.id],
      records: records,
      profileName: profileName,
      profileUpdatedAt: profileUpdatedAt,
    );
  }

  @override
  Future<void> acknowledgeUploads(List<int> outboxIds) async {
    if (outboxIds.isEmpty) return;
    await (_db.delete(_db.syncOutbox)..where((t) => t.id.isIn(outboxIds))).go();
  }

  @override
  Future<int> applyRemote(
    int learnerId,
    List<SyncRecord> records, {
    required int epoch,
  }) async {
    if (records.isEmpty) return 0;
    return _db.transaction(() async {
      final state = await (_db.select(
        _db.accountSyncStates,
      )..where((t) => t.learnerId.equals(learnerId))).getSingleOrNull();
      if (state == null || state.resetPending || state.epoch != epoch) {
        throw const StaleEpochException();
      }
      final mark = await _outboxHighWaterMark();
      var changed = 0;
      for (final record in records) {
        if (await _apply(learnerId, record)) changed++;
      }
      await (_db.delete(
        _db.syncOutbox,
      )..where((t) => t.id.isBiggerThanValue(mark))).go();
      return changed;
    });
  }

  @override
  Future<bool> applyRemoteProfile(
    int learnerId, {
    required String? name,
    required DateTime updatedAt,
  }) {
    return _db.transaction(() async {
      final learner = await (_db.select(
        _db.learners,
      )..where((t) => t.id.equals(learnerId))).getSingle();
      final local = learner.updatedAt;
      if (local != null && !local.isBefore(updatedAt)) return false;
      final mark = await _outboxHighWaterMark();
      await (_db.update(
        _db.learners,
      )..where((t) => t.id.equals(learnerId))).write(
        LearnersCompanion(name: Value(name), updatedAt: Value(updatedAt)),
      );
      await (_db.delete(
        _db.syncOutbox,
      )..where((t) => t.id.isBiggerThanValue(mark))).go();
      return learner.name != name;
    });
  }

  @override
  Future<void> wipeProgress(int learnerId) =>
      _db.resetProgressForLearner(learnerId);

  Future<int> _outboxHighWaterMark() async {
    final max = _db.syncOutbox.id.max();
    final row = await (_db.selectOnly(
      _db.syncOutbox,
    )..addColumns([max])).getSingle();
    return row.read(max) ?? 0;
  }

  /// Merges [remote] into the matching local row (inserting it if there is
  /// none). Returns whether the local row changed.
  Future<bool> _apply(int learnerId, SyncRecord remote) async {
    final f = remote.fields;
    switch (remote.collection) {
      case SyncCollection.attempts:
        final existing = await (_db.select(
          _db.activityAttempts,
        )..where((t) => t.uuid.equals(f['uuid']! as String))).getSingleOrNull();
        // Answers never change once recorded: present means up to date.
        if (existing != null) return false;
        final id = await _db
            .into(_db.activityAttempts)
            .insert(
              ActivityAttemptsCompanion.insert(
                uuid: f['uuid']! as String,
                learnerId: learnerId,
                activityId: f['activityId']! as String,
                lessonId: Value(f['lessonId'] as String?),
                sessionType: f['sessionType']! as String,
                sessionId: Value(f['sessionId'] as String?),
                mode: f['mode']! as String,
                evidenceSkill: f['evidenceSkill']! as String,
                rawAnswer: Value(f['rawAnswer'] as String?),
                isCorrect: Value(f['isCorrect'] as bool?),
                score: Value(f['score'] as double?),
                criteriaScores: Value(f['criteriaScores'] as String?),
                wasFallback: Value(f['wasFallback']! as bool),
                attemptedAt: f['attemptedAt']! as DateTime,
                updatedAt: f['updatedAt']! as DateTime,
              ),
            );
        for (final canDoId in f['canDoIds']! as List<String>) {
          await _db
              .into(_db.activityAttemptCanDos)
              .insert(
                ActivityAttemptCanDosCompanion.insert(
                  attemptId: id,
                  canDoId: canDoId,
                ),
              );
        }
        return true;

      case SyncCollection.dailyTasks:
        final existing = await (_db.select(
          _db.dailyTaskEvents,
        )..where((t) => t.uuid.equals(f['uuid']! as String))).getSingleOrNull();
        if (existing != null) return false;
        await _db
            .into(_db.dailyTaskEvents)
            .insert(
              DailyTaskEventsCompanion.insert(
                uuid: f['uuid']! as String,
                learnerId: learnerId,
                taskType: f['taskType']! as String,
                occurredAt: f['occurredAt']! as DateTime,
              ),
            );
        return true;

      case SyncCollection.testAttempts:
        return _applyTestAttempt(learnerId, remote);

      case SyncCollection.lessonProgress:
        final existing =
            await (_db.select(_db.lessonProgress)..where(
                  (t) =>
                      t.learnerId.equals(learnerId) &
                      t.lessonId.equals(f['lessonId']! as String),
                ))
                .getSingleOrNull();
        final merged = _mergedOrNull(
          existing == null ? null : lessonFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = LessonProgressCompanion(
          unitId: Value(m['unitId']! as String),
          state: Value(m['state']! as String),
          lastActivityId: Value(m['lastActivityId'] as String?),
          lastPositionUpdatedAt: Value(m['lastPositionUpdatedAt'] as DateTime?),
          updatedAt: Value(m['updatedAt']! as DateTime),
        );
        if (existing == null) {
          await _db
              .into(_db.lessonProgress)
              .insert(
                values.copyWith(
                  uuid: Value(_uuid.v4()),
                  learnerId: Value(learnerId),
                  lessonId: Value(m['lessonId']! as String),
                ),
              );
        } else {
          await (_db.update(
            _db.lessonProgress,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;

      case SyncCollection.vocabularyReview:
        final lexiconId = f['lexiconId'] as String?;
        final chunkId = f['chunkId'] as String?;
        if ((lexiconId == null) == (chunkId == null)) return false;
        final query = _db.select(_db.vocabularyReviewState)
          ..where((t) => t.learnerId.equals(learnerId));
        if (lexiconId != null) {
          query.where((t) => t.lexiconId.equals(lexiconId));
        } else {
          query.where((t) => t.chunkId.equals(chunkId!));
        }
        final existing = await query.getSingleOrNull();
        final merged = _mergedOrNull(
          existing == null ? null : vocabularyFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = VocabularyReviewStateCompanion(
          isFavorite: Value(m['isFavorite']! as bool),
          favoriteUpdatedAt: Value(m['favoriteUpdatedAt'] as DateTime?),
          confidenceMarker: Value(m['confidenceMarker'] as String?),
          easeFactor: Value(m['easeFactor']! as double),
          intervalDays: Value(m['intervalDays']! as int),
          repetitions: Value(m['repetitions']! as int),
          dueAt: Value(m['dueAt'] as DateTime?),
          lastReviewedAt: Value(m['lastReviewedAt'] as DateTime?),
          updatedAt: Value(m['updatedAt']! as DateTime),
        );
        if (existing == null) {
          await _db
              .into(_db.vocabularyReviewState)
              .insert(
                values.copyWith(
                  uuid: Value(_uuid.v4()),
                  learnerId: Value(learnerId),
                  lexiconId: Value(lexiconId),
                  chunkId: Value(chunkId),
                ),
              );
        } else {
          await (_db.update(
            _db.vocabularyReviewState,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;

      case SyncCollection.grammarReview:
        final grammarId = f['grammarId']! as String;
        final existing =
            await (_db.select(_db.grammarReviewState)..where(
                  (t) =>
                      t.learnerId.equals(learnerId) &
                      t.grammarId.equals(grammarId),
                ))
                .getSingleOrNull();
        final merged = _mergedOrNull(
          existing == null ? null : grammarFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = GrammarReviewStateCompanion(
          isFavorite: Value(m['isFavorite']! as bool),
          favoriteUpdatedAt: Value(m['favoriteUpdatedAt'] as DateTime?),
          markedReviewedAt: Value(m['markedReviewedAt'] as DateTime?),
          updatedAt: Value(m['updatedAt']! as DateTime),
        );
        if (existing == null) {
          await _db
              .into(_db.grammarReviewState)
              .insert(
                values.copyWith(
                  uuid: Value(_uuid.v4()),
                  learnerId: Value(learnerId),
                  grammarId: Value(grammarId),
                ),
              );
        } else {
          await (_db.update(
            _db.grammarReviewState,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;

      case SyncCollection.enrolments:
        final levelId = f['levelId']! as String;
        final courseId = f['courseId']! as String;
        // A pre-v5 row knows its course but not yet its level.
        final existing =
            await (_db.select(_db.courseEnrolments)..where(
                  (t) =>
                      t.learnerId.equals(learnerId) &
                      (t.levelId.equals(levelId) |
                          (t.levelId.isNull() & t.courseId.equals(courseId))),
                ))
                .getSingleOrNull();
        final merged = _mergedOrNull(
          existing == null
              ? null
              : enrolmentFields(existing, levelId: existing.levelId ?? levelId),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = CourseEnrolmentsCompanion(
          courseId: Value(m['courseId']! as String),
          contentVersion: Value(m['contentVersion']! as String),
          enrolledAt: Value(m['enrolledAt']! as DateTime),
          status: Value(m['status']! as String),
          levelId: Value(levelId),
          lastSelectedAt: Value(m['lastSelectedAt'] as DateTime?),
          unlockedAt: Value(m['unlockedAt'] as DateTime?),
        );
        if (existing == null) {
          await _db
              .into(_db.courseEnrolments)
              .insert(
                values.copyWith(
                  uuid: Value(_uuid.v4()),
                  learnerId: Value(learnerId),
                ),
              );
        } else {
          await (_db.update(
            _db.courseEnrolments,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;
    }
  }

  Future<bool> _applyTestAttempt(int learnerId, SyncRecord remote) async {
    final f = remote.fields;
    final uuid = f['uuid']! as String;
    switch (f['kind']) {
      case 'placement':
        final existing = await (_db.select(
          _db.placementAttempts,
        )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
        if (existing != null && existing.learnerId != learnerId) return false;
        final merged = _mergedOrNull(
          existing == null ? null : placementFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = PlacementAttemptsCompanion(
          startedAt: Value(m['startedAt']! as DateTime),
          completedAt: Value(m['completedAt'] as DateTime?),
          stageReached: Value(m['stageReached'] as int? ?? 0),
          outcome: Value(m['outcome'] as String?),
          recommendedUnitId: Value(m['recommendedUnitId'] as String?),
          confidenceSelfReports: Value(m['confidenceSelfReports'] as String?),
          itemSamplingSeed: Value(m['itemSamplingSeed'] as String?),
        );
        if (existing == null) {
          await _db
              .into(_db.placementAttempts)
              .insert(
                values.copyWith(uuid: Value(uuid), learnerId: Value(learnerId)),
              );
        } else {
          await (_db.update(
            _db.placementAttempts,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;
      case 'finalMission':
        final existing = await (_db.select(
          _db.finalMissionAttempts,
        )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
        if (existing != null && existing.learnerId != learnerId) return false;
        if (f['courseId'] == null) return false;
        final merged = _mergedOrNull(
          existing == null ? null : missionFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = FinalMissionAttemptsCompanion(
          courseId: Value(m['courseId']! as String),
          startedAt: Value(m['startedAt']! as DateTime),
          completedAt: Value(m['completedAt'] as DateTime?),
          stagesCompleted: Value(m['stagesCompleted'] as String?),
          outcome: Value(m['outcome'] as String?),
        );
        if (existing == null) {
          await _db
              .into(_db.finalMissionAttempts)
              .insert(
                values.copyWith(uuid: Value(uuid), learnerId: Value(learnerId)),
              );
        } else {
          await (_db.update(
            _db.finalMissionAttempts,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;
      case 'finalAssessment':
        final existing = await (_db.select(
          _db.finalAssessmentAttempts,
        )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
        if (existing != null && existing.learnerId != learnerId) return false;
        if (f['courseId'] == null) return false;
        final merged = _mergedOrNull(
          existing == null ? null : assessmentFields(existing),
          remote,
        );
        if (merged == null) return false;
        final m = merged.fields;
        final values = FinalAssessmentAttemptsCompanion(
          courseId: Value(m['courseId']! as String),
          startedAt: Value(m['startedAt']! as DateTime),
          completedAt: Value(m['completedAt'] as DateTime?),
          sectionResults: Value(m['sectionResults'] as String?),
          outcomeSummary: Value(m['outcomeSummary'] as String?),
        );
        if (existing == null) {
          await _db
              .into(_db.finalAssessmentAttempts)
              .insert(
                values.copyWith(uuid: Value(uuid), learnerId: Value(learnerId)),
              );
        } else {
          await (_db.update(
            _db.finalAssessmentAttempts,
          )..where((t) => t.id.equals(existing.id))).write(values);
        }
        return true;
      default:
        return false; // a kind this version of the app doesn't know
    }
  }

  /// The record the local row should hold after merging [remote] into
  /// [localFields] (null when there is no local row), or null when the
  /// local row already holds it.
  SyncRecord? _mergedOrNull(
    Map<String, Object?>? localFields,
    SyncRecord remote,
  ) {
    if (localFields == null) return remote;
    final local = SyncRecord(remote.collection, remote.docId, localFields);
    final merged = mergeRecords(local, remote);
    return merged == local ? null : merged;
  }

  SyncRecord _record(SyncCollection collection, Map<String, Object?> fields) =>
      SyncRecord(collection, collection.docIdFor(fields), fields);
}

// Row → record fields. Every time is converted to UTC, the form records
// are compared and stored in.

Map<String, Object?> attemptFields(ActivityAttempt r, List<String> canDoIds) =>
    {
      'uuid': r.uuid,
      'activityId': r.activityId,
      'lessonId': r.lessonId,
      'sessionType': r.sessionType,
      'sessionId': r.sessionId,
      'mode': r.mode,
      'evidenceSkill': r.evidenceSkill,
      'rawAnswer': r.rawAnswer,
      'isCorrect': r.isCorrect,
      'score': r.score,
      'criteriaScores': r.criteriaScores,
      'wasFallback': r.wasFallback,
      'attemptedAt': r.attemptedAt.toUtc(),
      'updatedAt': r.updatedAt.toUtc(),
      'canDoIds': canDoIds,
    };

Map<String, Object?> lessonFields(LessonProgressData r) => {
  'lessonId': r.lessonId,
  'unitId': r.unitId,
  'state': r.state,
  'lastActivityId': r.lastActivityId,
  'lastPositionUpdatedAt': r.lastPositionUpdatedAt?.toUtc(),
  'updatedAt': r.updatedAt.toUtc(),
};

Map<String, Object?> vocabularyFields(VocabularyReviewStateData r) => {
  'lexiconId': r.lexiconId,
  'chunkId': r.chunkId,
  'isFavorite': r.isFavorite,
  'favoriteUpdatedAt': r.favoriteUpdatedAt?.toUtc(),
  'confidenceMarker': r.confidenceMarker,
  'easeFactor': r.easeFactor,
  'intervalDays': r.intervalDays,
  'repetitions': r.repetitions,
  'dueAt': r.dueAt?.toUtc(),
  'lastReviewedAt': r.lastReviewedAt?.toUtc(),
  'updatedAt': r.updatedAt.toUtc(),
};

Map<String, Object?> grammarFields(GrammarReviewStateData r) => {
  'grammarId': r.grammarId,
  'isFavorite': r.isFavorite,
  'favoriteUpdatedAt': r.favoriteUpdatedAt?.toUtc(),
  'markedReviewedAt': r.markedReviewedAt?.toUtc(),
  'updatedAt': r.updatedAt.toUtc(),
};

Map<String, Object?> enrolmentFields(CourseEnrolment r, {String? levelId}) => {
  'levelId': levelId ?? r.levelId,
  'courseId': r.courseId,
  'contentVersion': r.contentVersion,
  'enrolledAt': r.enrolledAt.toUtc(),
  'status': r.status,
  'lastSelectedAt': r.lastSelectedAt?.toUtc(),
  'unlockedAt': r.unlockedAt?.toUtc(),
};

Map<String, Object?> _testFields(
  String kind, {
  required String uuid,
  required DateTime startedAt,
  String? courseId,
  DateTime? completedAt,
  int? stageReached,
  String? outcome,
  String? recommendedUnitId,
  String? confidenceSelfReports,
  String? itemSamplingSeed,
  String? stagesCompleted,
  String? sectionResults,
  String? outcomeSummary,
}) => {
  'uuid': uuid,
  'kind': kind,
  'courseId': courseId,
  'startedAt': startedAt.toUtc(),
  'completedAt': completedAt?.toUtc(),
  'stageReached': stageReached,
  'outcome': outcome,
  'recommendedUnitId': recommendedUnitId,
  'confidenceSelfReports': confidenceSelfReports,
  'itemSamplingSeed': itemSamplingSeed,
  'stagesCompleted': stagesCompleted,
  'sectionResults': sectionResults,
  'outcomeSummary': outcomeSummary,
};

Map<String, Object?> placementFields(PlacementAttempt r) => _testFields(
  'placement',
  uuid: r.uuid,
  startedAt: r.startedAt,
  completedAt: r.completedAt,
  stageReached: r.stageReached,
  outcome: r.outcome,
  recommendedUnitId: r.recommendedUnitId,
  confidenceSelfReports: r.confidenceSelfReports,
  itemSamplingSeed: r.itemSamplingSeed,
);

Map<String, Object?> missionFields(FinalMissionAttempt r) => _testFields(
  'finalMission',
  uuid: r.uuid,
  courseId: r.courseId,
  startedAt: r.startedAt,
  completedAt: r.completedAt,
  stagesCompleted: r.stagesCompleted,
  outcome: r.outcome,
);

Map<String, Object?> assessmentFields(FinalAssessmentAttempt r) => _testFields(
  'finalAssessment',
  uuid: r.uuid,
  courseId: r.courseId,
  startedAt: r.startedAt,
  completedAt: r.completedAt,
  sectionResults: r.sectionResults,
  outcomeSummary: r.outcomeSummary,
);

Map<String, Object?> dailyTaskFields(DailyTaskEvent r) => {
  'uuid': r.uuid,
  'taskType': r.taskType,
  'occurredAt': r.occurredAt.toUtc(),
};

Map<SyncCollection, PullCursor> _decodeCursors(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) return const {};
  return {
    for (final collection in SyncCollection.values)
      collection: ?PullCursor.fromJson(decoded[collection.path]),
  };
}
