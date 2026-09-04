import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftActivityAttemptRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftActivityAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> attemptOn(DateTime day) async {
    final id = await repository.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A01',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
    );
    await (db.update(db.activityAttempts)..where((t) => t.id.equals(id))).write(
      ActivityAttemptsCompanion(attemptedAt: Value(day)),
    );
  }

  test('returns 0 with no attempts', () async {
    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 0);
  });

  test('counts consecutive days ending on asOf', () async {
    await attemptOn(DateTime.utc(2026, 9, 2));
    await attemptOn(DateTime.utc(2026, 9, 3));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 3);
  });

  test('stops counting at the first gap', () async {
    await attemptOn(DateTime.utc(2026, 9, 1));
    // gap on Sep 2
    await attemptOn(DateTime.utc(2026, 9, 3));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 2);
  });

  test('multiple attempts on the same day count once', () async {
    await attemptOn(DateTime.utc(2026, 9, 4));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 1);
  });
}
