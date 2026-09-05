import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'lessonProgressForUnit returns only rows for that unit and learner',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = DriftUnitLessonProgressRepository(db);

      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-1',
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );
      final otherLearnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-2',
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await repository.recordLessonPosition(
        learnerId: learnerId,
        lessonId: 'A1-U1-L1',
        unitId: 'A1-U1',
        lastActivityId: 'A1-U1-L1-A02',
      );
      await repository.recordLessonPosition(
        learnerId: learnerId,
        lessonId: 'A1-U1-L2',
        unitId: 'A1-U1',
        lastActivityId: 'A1-U1-L2-A01',
      );
      // Different unit — must not be returned.
      await repository.recordLessonPosition(
        learnerId: learnerId,
        lessonId: 'A1-U2-L1',
        unitId: 'A1-U2',
        lastActivityId: 'A1-U2-L1-A01',
      );
      // Different learner, same unit — must not be returned.
      await repository.recordLessonPosition(
        learnerId: otherLearnerId,
        lessonId: 'A1-U1-L1',
        unitId: 'A1-U1',
        lastActivityId: 'A1-U1-L1-A01',
      );

      final rows = await repository.lessonProgressForUnit(
        learnerId: learnerId,
        unitId: 'A1-U1',
      );

      expect(rows.map((r) => r.lessonId).toSet(), {'A1-U1-L1', 'A1-U1-L2'});
    },
  );

  test('allLessonProgress returns every unit\'s rows for that learner, '
      'excluding other learners', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftUnitLessonProgressRepository(db);

    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
    final otherLearnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-2',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    await repository.recordLessonPosition(
      learnerId: learnerId,
      lessonId: 'A1-U0-L1',
      unitId: 'A1-U0',
      lastActivityId: 'A1-U0-L1-A01',
    );
    await repository.recordLessonPosition(
      learnerId: learnerId,
      lessonId: 'A1-U1-L1',
      unitId: 'A1-U1',
      lastActivityId: 'A1-U1-L1-A01',
    );
    await repository.recordLessonPosition(
      learnerId: otherLearnerId,
      lessonId: 'A1-U0-L1',
      unitId: 'A1-U0',
      lastActivityId: 'A1-U0-L1-A01',
    );

    final rows = await repository.allLessonProgress(learnerId: learnerId);

    expect(rows.map((r) => r.lessonId).toSet(), {'A1-U0-L1', 'A1-U1-L1'});
  });
}
