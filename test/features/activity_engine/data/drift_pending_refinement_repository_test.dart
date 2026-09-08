import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/activity_engine/data/drift_pending_refinement_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPendingRefinementRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftPendingRefinementRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
  });

  tearDown(() => db.close());

  test('enqueue then allPending round-trips every field', () async {
    await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      rawAnswer: 'See you at the park on Saturday!',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.5,
    );

    final pending = await repository.allPending();
    expect(pending, hasLength(1));
    expect(pending.single.activityId, 'A1-U5-L6-A05');
    expect(
      pending.single.canDoIds,
      '["A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE"]',
    );
    expect(pending.single.localScore, 0.5);
    expect(pending.single.attemptCount, 0);
    expect(pending.single.evidenceSkill, 'writing');
    expect(pending.single.wasFallback, isFalse);
  });

  test('enqueue preserves wasFallback for a typed-answer speaking '
      'fallback', () async {
    await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A06',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: '"A typed answer to a speaking task."',
      // wasFallback=true is always paired with the fallback skill — see
      // docs/DATA_MODEL.md.
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
      wasFallback: true,
    );

    final pending = await repository.allPending();
    expect(pending.single.wasFallback, isTrue);
    expect(pending.single.evidenceSkill, 'writing');
  });

  test(
    'recordFailedAttempt increments attemptCount and sets lastAttemptAt',
    () async {
      final id = await repository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-U5-L6-A05',
        lessonId: 'A1-U5-L6',
        unitId: 'A1-U5',
        canDoIds: const [],
        rawAnswer: 'answer',
        evidenceSkill: 'writing',
        mode: 'mastery',
        localScore: 0.0,
      );

      await repository.recordFailedAttempt(
        id: id,
        attemptedAt: DateTime.utc(2026, 9, 8, 10),
      );

      final pending = await repository.allPending();
      expect(pending.single.attemptCount, 1);
      // Drift's default SQLite DateTime storage round-trips to *local* time
      // regardless of how the value was written (see
      // https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#datetime-options),
      // and Dart's `DateTime.==` — unlike `isBefore`/`isAfter` — considers the
      // UTC/local flag, not just the instant. Compare instants directly so
      // this test passes regardless of the host machine's time zone.
      expect(
        pending.single.lastAttemptAt!.isAtSameMomentAs(
          DateTime.utc(2026, 9, 8, 10),
        ),
        isTrue,
      );
    },
  );

  test('remove deletes the row', () async {
    final id = await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );

    await repository.remove(id: id);

    expect(await repository.allPending(), isEmpty);
  });

  test('removeAllForLearner clears only that learner\'s rows', () async {
    final otherLearnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
    await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-TEST-A',
      lessonId: 'A1-TEST-L',
      unitId: 'A1-TEST',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );
    await repository.enqueue(
      learnerId: otherLearnerId,
      activityId: 'A1-TEST-B',
      lessonId: 'A1-TEST-L',
      unitId: 'A1-TEST',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );

    await repository.removeAllForLearner(learnerId: learnerId);

    final remaining = await repository.allPending();
    expect(remaining, hasLength(1));
    expect(remaining.single.learnerId, otherLearnerId);
  });
}
