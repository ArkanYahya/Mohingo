import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/assessment_attempt_repository.dart';

class DriftAssessmentAttemptRepository implements AssessmentAttemptRepository {
  DriftAssessmentAttemptRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<int> startPlacementAttempt({
    required int learnerId,
    required String itemSamplingSeed,
  }) {
    return _db
        .into(_db.placementAttempts)
        .insert(
          PlacementAttemptsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            startedAt: DateTime.now(),
            itemSamplingSeed: Value(itemSamplingSeed),
          ),
        );
  }

  @override
  Future<void> completePlacementAttempt({
    required int attemptId,
    required int stageReached,
    required String outcome,
    String? recommendedUnitId,
    String? confidenceSelfReportsJson,
  }) {
    return (_db.update(
      _db.placementAttempts,
    )..where((t) => t.id.equals(attemptId))).write(
      PlacementAttemptsCompanion(
        completedAt: Value(DateTime.now()),
        stageReached: Value(stageReached),
        outcome: Value(outcome),
        recommendedUnitId: Value(recommendedUnitId),
        confidenceSelfReports: Value(confidenceSelfReportsJson),
      ),
    );
  }

  @override
  Future<PlacementAttempt?> latestPlacementAttempt({required int learnerId}) {
    return (_db.select(_db.placementAttempts)
          ..where((t) => t.learnerId.equals(learnerId))
          // `id DESC` breaks ties when two attempts start within the same
          // clock tick (a fast retake, or back-to-back test calls) —
          // `startedAt` alone isn't a reliable "most recent" order then,
          // but the autoincrement id always is.
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<int> startFinalMissionAttempt({
    required int learnerId,
    required String courseId,
  }) {
    return _db
        .into(_db.finalMissionAttempts)
        .insert(
          FinalMissionAttemptsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            courseId: courseId,
            startedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> completeFinalMissionAttempt({
    required int attemptId,
    required String stagesCompletedJson,
    required String outcome,
  }) {
    return (_db.update(
      _db.finalMissionAttempts,
    )..where((t) => t.id.equals(attemptId))).write(
      FinalMissionAttemptsCompanion(
        completedAt: Value(DateTime.now()),
        stagesCompleted: Value(stagesCompletedJson),
        outcome: Value(outcome),
      ),
    );
  }

  @override
  Future<FinalMissionAttempt?> latestFinalMissionAttempt({
    required int learnerId,
    required String courseId,
  }) {
    return (_db.select(_db.finalMissionAttempts)
          ..where(
            (t) => t.learnerId.equals(learnerId) & t.courseId.equals(courseId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<int> startFinalAssessmentAttempt({
    required int learnerId,
    required String courseId,
  }) {
    return _db
        .into(_db.finalAssessmentAttempts)
        .insert(
          FinalAssessmentAttemptsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            courseId: courseId,
            startedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> completeFinalAssessmentAttempt({
    required int attemptId,
    required String sectionResultsJson,
    required String outcomeSummaryJson,
  }) {
    return (_db.update(
      _db.finalAssessmentAttempts,
    )..where((t) => t.id.equals(attemptId))).write(
      FinalAssessmentAttemptsCompanion(
        completedAt: Value(DateTime.now()),
        sectionResults: Value(sectionResultsJson),
        outcomeSummary: Value(outcomeSummaryJson),
      ),
    );
  }

  @override
  Future<FinalAssessmentAttempt?> latestFinalAssessmentAttempt({
    required int learnerId,
    required String courseId,
  }) {
    return (_db.select(_db.finalAssessmentAttempts)
          ..where(
            (t) => t.learnerId.equals(learnerId) & t.courseId.equals(courseId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
