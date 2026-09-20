import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';

void main() {
  late AppDatabase db;
  late DriftLearnerRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLearnerRepository(db);
    final learner = await repository.getOrCreateLearner();
    learnerId = learner.id;
  });

  tearDown(() => db.close());

  test(
    'enrolling records the level, and enrolling again changes nothing',
    () async {
      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a1',
        courseId: 'EN-A1-V2',
        contentVersion: 'v1',
      );
      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a1',
        courseId: 'EN-A1-V2',
        contentVersion: 'v2',
      );

      final rows = await repository.enrolments(learnerId: learnerId);
      expect(rows, hasLength(1));
      expect(rows.single.levelId, 'a1');
      expect(rows.single.contentVersion, 'v1');
    },
  );

  test(
    'a row written before levelId existed is backfilled, not duplicated',
    () async {
      await db
          .into(db.courseEnrolments)
          .insert(
            CourseEnrolmentsCompanion.insert(
              uuid: 'legacy',
              learnerId: learnerId,
              courseId: 'EN-A1-V2',
              contentVersion: 'v1',
              enrolledAt: DateTime.utc(2026, 9, 1),
              status: 'active',
            ),
          );

      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a1',
        courseId: 'EN-A1-V2',
        contentVersion: 'v1',
      );

      final rows = await repository.enrolments(learnerId: learnerId);
      expect(rows, hasLength(1));
      expect(rows.single.uuid, 'legacy');
      expect(rows.single.levelId, 'a1');
    },
  );

  test(
    'selecting a level stamps it, and selecting another moves the stamp',
    () async {
      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a1',
        courseId: 'EN-A1-V2',
        contentVersion: 'v1',
      );
      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a2',
        courseId: 'EN-A2-V1',
        contentVersion: 'v1',
      );

      await repository.markLevelSelected(
        learnerId: learnerId,
        levelId: 'a1',
        at: DateTime.utc(2026, 9, 19),
      );
      await repository.markLevelSelected(
        learnerId: learnerId,
        levelId: 'a2',
        at: DateTime.utc(2026, 9, 20),
      );

      final a1 = await repository.enrolmentForLevel(
        learnerId: learnerId,
        levelId: 'a1',
      );
      final a2 = await repository.enrolmentForLevel(
        learnerId: learnerId,
        levelId: 'a2',
      );
      // Compared via toUtc(): drift round-trips DateTimeColumn values as
      // unix timestamps and hands them back in local time (same instant,
      // different `isUtc` flag) — and Dart's DateTime equality treats that
      // flag as significant, so a raw `==` against a UTC literal is
      // timezone-dependent even though the underlying instant matches
      // exactly.
      expect(a1!.lastSelectedAt?.toUtc(), DateTime.utc(2026, 9, 19));
      expect(a2!.lastSelectedAt?.toUtc(), DateTime.utc(2026, 9, 20));
    },
  );

  test(
    'unlocking is idempotent — the first time is the time that sticks',
    () async {
      await repository.ensureEnrolled(
        learnerId: learnerId,
        levelId: 'a2',
        courseId: 'EN-A2-V1',
        contentVersion: 'v1',
      );

      await repository.markLevelUnlocked(
        learnerId: learnerId,
        levelId: 'a2',
        at: DateTime.utc(2026, 9, 20),
      );
      await repository.markLevelUnlocked(
        learnerId: learnerId,
        levelId: 'a2',
        at: DateTime.utc(2026, 9, 21),
      );

      final row = await repository.enrolmentForLevel(
        learnerId: learnerId,
        levelId: 'a2',
      );
      // Compared via toUtc() — see the comment in "selecting a level stamps
      // it" above. This also proves the *first* call's timestamp survives:
      // a naive re-write would show 9/21, not 9/20.
      expect(row!.unlockedAt?.toUtc(), DateTime.utc(2026, 9, 20));
    },
  );

  test(
    'selecting or unlocking a level the learner never started does nothing',
    () async {
      await repository.markLevelSelected(learnerId: learnerId, levelId: 'b1');
      await repository.markLevelUnlocked(learnerId: learnerId, levelId: 'b1');

      expect(await repository.enrolments(learnerId: learnerId), isEmpty);
    },
  );
}
