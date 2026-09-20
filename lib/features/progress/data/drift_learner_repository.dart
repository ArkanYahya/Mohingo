import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/learner_repository.dart';

class DriftLearnerRepository implements LearnerRepository {
  DriftLearnerRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<Learner> getOrCreateLearner() async {
    final existing = await (_db.select(
      _db.learners,
    )..where((t) => t.isActive.equals(true))).getSingleOrNull();
    if (existing != null) return existing;

    final id = await _db
        .into(_db.learners)
        .insert(
          LearnersCompanion.insert(uuid: _uuid.v4(), createdAt: DateTime.now()),
        );
    return (_db.select(
      _db.learners,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  @override
  Future<void> ensureEnrolled({
    required int learnerId,
    required String levelId,
    required String courseId,
    required String contentVersion,
  }) async {
    final existing =
        await (_db.select(_db.courseEnrolments)..where(
              (t) =>
                  t.learnerId.equals(learnerId) &
                  (t.levelId.equals(levelId) | t.courseId.equals(courseId)),
            ))
            .getSingleOrNull();
    if (existing != null) {
      // A row written before schema v5 knows its course but not its level.
      if (existing.levelId == null) {
        await (_db.update(_db.courseEnrolments)
              ..where((t) => t.id.equals(existing.id)))
            .write(CourseEnrolmentsCompanion(levelId: Value(levelId)));
      }
      return;
    }

    await _db
        .into(_db.courseEnrolments)
        .insert(
          CourseEnrolmentsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            courseId: courseId,
            contentVersion: contentVersion,
            enrolledAt: DateTime.now(),
            status: 'active',
            levelId: Value(levelId),
          ),
        );
  }

  @override
  Future<List<CourseEnrolment>> enrolments({required int learnerId}) {
    return (_db.select(
      _db.courseEnrolments,
    )..where((t) => t.learnerId.equals(learnerId))).get();
  }

  @override
  Future<CourseEnrolment?> enrolmentForLevel({
    required int learnerId,
    required String levelId,
  }) {
    return (_db.select(_db.courseEnrolments)..where(
          (t) => t.learnerId.equals(learnerId) & t.levelId.equals(levelId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<void> markLevelSelected({
    required int learnerId,
    required String levelId,
    DateTime? at,
  }) async {
    await (_db.update(_db.courseEnrolments)..where(
          (t) => t.learnerId.equals(learnerId) & t.levelId.equals(levelId),
        ))
        .write(
          CourseEnrolmentsCompanion(
            lastSelectedAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<void> markLevelUnlocked({
    required int learnerId,
    required String levelId,
    DateTime? at,
  }) async {
    final existing = await enrolmentForLevel(
      learnerId: learnerId,
      levelId: levelId,
    );
    if (existing == null || existing.unlockedAt != null) return;
    await (_db.update(
      _db.courseEnrolments,
    )..where((t) => t.id.equals(existing.id))).write(
      CourseEnrolmentsCompanion(unlockedAt: Value(at ?? DateTime.now())),
    );
  }

  @override
  Future<void> updateName({
    required int learnerId,
    required String name,
  }) async {
    await (_db.update(
      _db.learners,
    )..where((t) => t.id.equals(learnerId))).write(
      LearnersCompanion(name: Value(name.trim().isEmpty ? null : name.trim())),
    );
  }
}
