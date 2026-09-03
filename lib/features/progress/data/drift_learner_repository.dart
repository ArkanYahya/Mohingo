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
    required String courseId,
    required String contentVersion,
  }) async {
    final existing =
        await (_db.select(_db.courseEnrolments)..where(
              (t) =>
                  t.learnerId.equals(learnerId) & t.courseId.equals(courseId),
            ))
            .getSingleOrNull();
    if (existing != null) return;

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
          ),
        );
  }
}
