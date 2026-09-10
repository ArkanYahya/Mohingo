import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_daily_task_event_repository.dart';
import 'package:mohingo/features/progress/domain/repositories/daily_task_event_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftDailyTaskEventRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftDailyTaskEventRepository(db);
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

  test('returns zero counts with no events', () async {
    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.lesson, 0);
    expect(counts.vocabularyReview, 0);
    expect(counts.speaking, 0);
  });

  test('recording a lesson event counts it under lesson only', () async {
    await repository.recordEvent(
      learnerId: learnerId,
      taskType: DailyTaskType.lesson,
      occurredAt: DateTime.utc(2026, 9, 4),
    );

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.lesson, 1);
    expect(counts.vocabularyReview, 0);
    expect(counts.speaking, 0);
  });

  test('multiple vocabularyReview events on the same day all count', () async {
    for (var i = 0; i < 3; i++) {
      await repository.recordEvent(
        learnerId: learnerId,
        taskType: DailyTaskType.vocabularyReview,
        occurredAt: DateTime.utc(2026, 9, 4),
      );
    }

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.vocabularyReview, 3);
  });

  test('a speaking event counts under speaking only', () async {
    await repository.recordEvent(
      learnerId: learnerId,
      taskType: DailyTaskType.speaking,
      occurredAt: DateTime.utc(2026, 9, 4),
    );

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.speaking, 1);
    expect(counts.lesson, 0);
  });

  test('events from a previous day are not counted as today', () async {
    await repository.recordEvent(
      learnerId: learnerId,
      taskType: DailyTaskType.lesson,
      occurredAt: DateTime.utc(2026, 9, 3),
    );

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.lesson, 0);
  });

  test('events for a different learner are never counted', () async {
    final otherLearnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-2',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );
    await repository.recordEvent(
      learnerId: otherLearnerId,
      taskType: DailyTaskType.lesson,
      occurredAt: DateTime.utc(2026, 9, 4),
    );

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(counts.lesson, 0);
  });

  test('occurredAt defaults to now when omitted', () async {
    await repository.recordEvent(
      learnerId: learnerId,
      taskType: DailyTaskType.speaking,
    );

    final counts = await repository.countsForToday(
      learnerId: learnerId,
      asOf: DateTime.now(),
    );
    expect(counts.speaking, 1);
  });
}
