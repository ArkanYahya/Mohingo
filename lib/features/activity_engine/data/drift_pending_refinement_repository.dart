import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/pending_refinement_repository.dart';

class DriftPendingRefinementRepository implements PendingRefinementRepository {
  DriftPendingRefinementRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<int> enqueue({
    required int learnerId,
    required String activityId,
    required String lessonId,
    required String unitId,
    required List<String> canDoIds,
    required String rawAnswer,
    required String evidenceSkill,
    required String mode,
    required double localScore,
    bool wasFallback = false,
  }) {
    final now = DateTime.now();
    return _db
        .into(_db.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            activityId: activityId,
            lessonId: lessonId,
            unitId: unitId,
            canDoIds: jsonEncode(canDoIds),
            rawAnswer: rawAnswer,
            evidenceSkill: evidenceSkill,
            wasFallback: Value(wasFallback),
            mode: mode,
            localScore: localScore,
            submittedAt: now,
          ),
        );
  }

  @override
  Future<List<PendingOnlineRefinement>> allPending() {
    return _db.select(_db.pendingOnlineRefinements).get();
  }

  @override
  Future<void> recordFailedAttempt({
    required int id,
    required DateTime attemptedAt,
  }) async {
    final row = await (_db.select(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).write(
      PendingOnlineRefinementsCompanion(
        attemptCount: Value(row.attemptCount + 1),
        lastAttemptAt: Value(attemptedAt),
      ),
    );
  }

  @override
  Future<void> remove({required int id}) async {
    await (_db.delete(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> removeAllForLearner({required int learnerId}) async {
    await (_db.delete(
      _db.pendingOnlineRefinements,
    )..where((t) => t.learnerId.equals(learnerId))).go();
  }
}
