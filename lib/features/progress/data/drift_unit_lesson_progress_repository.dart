import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/unit_lesson_progress_repository.dart';

class DriftUnitLessonProgressRepository
    implements UnitLessonProgressRepository {
  DriftUnitLessonProgressRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<UnitProgressData?> unitProgress({
    required int learnerId,
    required String unitId,
  }) {
    return (_db.select(_db.unitProgress)..where(
          (t) => t.learnerId.equals(learnerId) & t.unitId.equals(unitId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<List<UnitProgressData>> allUnitProgress({required int learnerId}) {
    return (_db.select(
      _db.unitProgress,
    )..where((t) => t.learnerId.equals(learnerId))).get();
  }

  @override
  Future<void> upsertUnitProgress({
    required int learnerId,
    required String unitId,
    required UnitProgressState state,
    DateTime? masteredAt,
  }) async {
    final now = DateTime.now();
    final existing = await unitProgress(learnerId: learnerId, unitId: unitId);
    if (existing == null) {
      await _db
          .into(_db.unitProgress)
          .insert(
            UnitProgressCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              unitId: unitId,
              state: state.name,
              lastActivityAt: Value(now),
              masteredAt: Value(masteredAt),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.unitProgress,
      )..where((t) => t.id.equals(existing.id))).write(
        UnitProgressCompanion(
          state: Value(state.name),
          lastActivityAt: Value(now),
          masteredAt: Value(masteredAt),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<LessonProgressData?> lessonProgress({
    required int learnerId,
    required String lessonId,
  }) {
    return (_db.select(_db.lessonProgress)..where(
          (t) => t.learnerId.equals(learnerId) & t.lessonId.equals(lessonId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<List<LessonProgressData>> lessonProgressForUnit({
    required int learnerId,
    required String unitId,
  }) {
    return (_db.select(_db.lessonProgress)..where(
          (t) => t.learnerId.equals(learnerId) & t.unitId.equals(unitId),
        ))
        .get();
  }

  @override
  Future<void> recordLessonPosition({
    required int learnerId,
    required String lessonId,
    required String unitId,
    required String lastActivityId,
  }) async {
    final now = DateTime.now();
    final existing = await lessonProgress(
      learnerId: learnerId,
      lessonId: lessonId,
    );
    if (existing == null) {
      await _db
          .into(_db.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              lessonId: lessonId,
              unitId: unitId,
              state: UnitProgressState.inProgress.name,
              lastActivityId: Value(lastActivityId),
              lastPositionUpdatedAt: Value(now),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.lessonProgress,
      )..where((t) => t.id.equals(existing.id))).write(
        LessonProgressCompanion(
          lastActivityId: Value(lastActivityId),
          lastPositionUpdatedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
