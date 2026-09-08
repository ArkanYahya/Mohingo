import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../content/models/domain_definitions.dart';
import '../../../data/local/database.dart';
import '../domain/repositories/activity_attempt_repository.dart';

class DriftActivityAttemptRepository implements ActivityAttemptRepository {
  DriftActivityAttemptRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<int> recordAttempt({
    required int learnerId,
    required String activityId,
    String? lessonId,
    required String sessionType,
    String? sessionId,
    required ActivityMode mode,
    required Skill evidenceSkill,
    required List<String> canDoIds,
    String? rawAnswer,
    bool? isCorrect,
    double? score,
    String? criteriaScores,
    bool wasFallback = false,
  }) async {
    final now = DateTime.now();
    return _db.transaction(() async {
      final attemptId = await _db
          .into(_db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              activityId: activityId,
              lessonId: Value(lessonId),
              sessionType: sessionType,
              sessionId: Value(sessionId),
              mode: mode.name,
              evidenceSkill: evidenceSkill.name,
              rawAnswer: Value(rawAnswer),
              isCorrect: Value(isCorrect),
              score: Value(score),
              criteriaScores: Value(criteriaScores),
              wasFallback: Value(wasFallback),
              attemptedAt: now,
              updatedAt: now,
            ),
          );

      for (final canDoId in canDoIds) {
        await _db
            .into(_db.activityAttemptCanDos)
            .insert(
              ActivityAttemptCanDosCompanion.insert(
                attemptId: attemptId,
                canDoId: canDoId,
              ),
            );
      }

      return attemptId;
    });
  }

  @override
  Future<List<ActivityAttempt>> masteryEvidenceForObjective({
    required int learnerId,
    required String canDoId,
  }) async {
    final query =
        _db.select(_db.activityAttempts).join([
            innerJoin(
              _db.activityAttemptCanDos,
              _db.activityAttemptCanDos.attemptId.equalsExp(
                _db.activityAttempts.id,
              ),
            ),
          ])
          ..where(_db.activityAttempts.learnerId.equals(learnerId))
          ..where(_db.activityAttempts.mode.equals(ActivityMode.mastery.name))
          ..where(_db.activityAttempts.sessionType.equals('lesson'))
          ..where(_db.activityAttemptCanDos.canDoId.equals(canDoId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.activityAttempts)).toList();
  }

  @override
  Future<List<ActivityAttempt>> attemptsForLessons({
    required int learnerId,
    required List<String> lessonIds,
  }) async {
    if (lessonIds.isEmpty) return const [];
    return (_db.select(_db.activityAttempts)..where(
          (t) => t.learnerId.equals(learnerId) & t.lessonId.isIn(lessonIds),
        ))
        .get();
  }

  @override
  Future<int> currentStreakDays({
    required int learnerId,
    required DateTime asOf,
  }) async {
    final rows =
        await (_db.selectOnly(_db.activityAttempts)
              ..addColumns([_db.activityAttempts.attemptedAt])
              ..where(_db.activityAttempts.learnerId.equals(learnerId)))
            .get();

    final activeDates = <DateTime>{
      for (final row in rows)
        _dateOnly(row.read(_db.activityAttempts.attemptedAt)!),
    };

    var streak = 0;
    var day = _dateOnly(asOf);
    while (activeDates.contains(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Future<ActivityAttempt?> latestAttempt({
    required int learnerId,
    required String activityId,
  }) {
    final query = _db.select(_db.activityAttempts)
      ..where(
        (t) => t.learnerId.equals(learnerId) & t.activityId.equals(activityId),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.attemptedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
