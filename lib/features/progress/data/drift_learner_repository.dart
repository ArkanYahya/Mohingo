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
    final existing =
        await (_db.select(_db.learners)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing;
    return activateGuest();
  }

  @override
  Future<Learner> learnerById(int learnerId) {
    return (_db.select(
      _db.learners,
    )..where((t) => t.id.equals(learnerId))).getSingle();
  }

  @override
  Future<Learner?> learnerForAccount(String firebaseUid) {
    return (_db.select(
      _db.learners,
    )..where((t) => t.firebaseUid.equals(firebaseUid))).getSingleOrNull();
  }

  @override
  Future<void> forgetAccountLearner(String firebaseUid) async {
    final learner = await learnerForAccount(firebaseUid);
    if (learner == null || learner.isActive) return;
    await _db.deleteLearner(learner.id);
  }

  @override
  Future<Learner?> guestLearner() {
    return (_db.select(_db.learners)
          ..where((t) => t.firebaseUid.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<Learner> activateGuest() {
    return _db.transaction(() async {
      final guest = await guestLearner();
      final id =
          guest?.id ??
          await _db
              .into(_db.learners)
              .insert(
                LearnersCompanion.insert(
                  uuid: _uuid.v4(),
                  createdAt: DateTime.now(),
                ),
              );
      await activate(id);
      return learnerById(id);
    });
  }

  @override
  Future<void> activate(int learnerId) {
    return _db.transaction(() async {
      await (_db.update(_db.learners)
            ..where((t) => t.id.equals(learnerId).not()))
          .write(const LearnersCompanion(isActive: Value(false)));
      await (_db.update(_db.learners)..where((t) => t.id.equals(learnerId)))
          .write(const LearnersCompanion(isActive: Value(true)));
    });
  }

  @override
  Future<Learner> createAccountLearner(String firebaseUid) {
    return _db.transaction(() async {
      final id = await _db
          .into(_db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: _uuid.v4(),
              createdAt: DateTime.now(),
              firebaseUid: Value(firebaseUid),
              isActive: const Value(false),
            ),
          );
      await activate(id);
      return learnerById(id);
    });
  }

  @override
  Future<Learner> bindGuestToAccount({
    required int learnerId,
    required String firebaseUid,
  }) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(_db.learners)
                ..where((t) => t.id.equals(learnerId) & t.firebaseUid.isNull()))
              .write(LearnersCompanion(firebaseUid: Value(firebaseUid)));
      if (updated != 1) {
        throw StateError('learner $learnerId is not a guest');
      }
      await activate(learnerId);
      return learnerById(learnerId);
    });
  }

  @override
  Future<bool> hasProgress(int learnerId) async {
    Future<bool> any(TableInfo<Table, Object?> table) async {
      final row = await _db
          .customSelect(
            'SELECT 1 FROM ${table.actualTableName} '
            'WHERE learner_id = ? LIMIT 1',
            variables: [Variable.withInt(learnerId)],
            readsFrom: {table},
          )
          .getSingleOrNull();
      return row != null;
    }

    for (final table in <TableInfo<Table, Object?>>[
      _db.activityAttempts,
      _db.lessonProgress,
      _db.vocabularyReviewState,
      _db.grammarReviewState,
      _db.placementAttempts,
      _db.finalMissionAttempts,
      _db.finalAssessmentAttempts,
    ]) {
      if (await any(table)) return true;
    }
    return false;
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
      LearnersCompanion(
        name: Value(name.trim().isEmpty ? null : name.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
