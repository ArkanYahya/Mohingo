import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version is 1', () {
    expect(database.schemaVersion, 1);
  });

  test('can insert and read back a learner, with ar/en defaults', () async {
    final uuid = const Uuid().v4();
    await database
        .into(database.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: uuid,
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final rows = await database.select(database.learners).get();
    expect(rows, hasLength(1));
    expect(rows.single.uuid, uuid);
    expect(rows.single.nativeLanguage, 'ar');
    expect(rows.single.targetLanguage, 'en');
    expect(rows.single.isActive, isTrue);
  });

  test(
    'activity_attempts is insert-only: a replay appends, not overwrites',
    () async {
      final learnerId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      Future<int> recordAttempt() => database
          .into(database.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U1-L1-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await recordAttempt();
      await recordAttempt(); // a replay of the same activity

      final rows = await (database.select(
        database.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U1-L1-A01'))).get();
      expect(
        rows,
        hasLength(2),
        reason: 'a replay must append, never overwrite',
      );
    },
  );

  test('activity_attempt_can_dos normalizes an attempt\'s canDo ids', () async {
    final learnerId = await database
        .into(database.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final attemptId = await database
        .into(database.activityAttempts)
        .insert(
          ActivityAttemptsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U1-L1-A01',
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'listening',
            attemptedAt: DateTime.utc(2026, 9, 2),
            updatedAt: DateTime.utc(2026, 9, 2),
          ),
        );

    await database
        .into(database.activityAttemptCanDos)
        .insert(
          ActivityAttemptCanDosCompanion.insert(
            attemptId: attemptId,
            canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
          ),
        );

    final joined = await (database.select(
      database.activityAttemptCanDos,
    )..where((t) => t.attemptId.equals(attemptId))).get();
    expect(joined, hasLength(1));
    expect(joined.single.canDoId, 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO');
  });

  test(
    'a speaking fallback is recorded as writing evidence, not speaking',
    () async {
      final learnerId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await database
          .into(database.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L1-A04',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing', // fallback, not spokenProduction
              wasFallback: const Value(true),
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      final rows = await (database.select(
        database.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L1-A04'))).get();
      expect(rows.single.wasFallback, isTrue);
      expect(rows.single.evidenceSkill, 'writing');
    },
  );
}
