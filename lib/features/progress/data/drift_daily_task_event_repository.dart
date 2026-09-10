import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/daily_task_event_repository.dart';

class DriftDailyTaskEventRepository implements DailyTaskEventRepository {
  DriftDailyTaskEventRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<void> recordEvent({
    required int learnerId,
    required DailyTaskType taskType,
    DateTime? occurredAt,
  }) async {
    await _db
        .into(_db.dailyTaskEvents)
        .insert(
          DailyTaskEventsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            taskType: taskType.name,
            occurredAt: occurredAt ?? DateTime.now(),
          ),
        );
  }

  @override
  Future<DailyTaskCounts> countsForToday({
    required int learnerId,
    required DateTime asOf,
  }) async {
    final today = _dateOnly(asOf);
    final rows =
        await (_db.selectOnly(_db.dailyTaskEvents)
              ..addColumns([
                _db.dailyTaskEvents.taskType,
                _db.dailyTaskEvents.occurredAt,
              ])
              ..where(_db.dailyTaskEvents.learnerId.equals(learnerId)))
            .get();

    var lesson = 0;
    var vocabularyReview = 0;
    var speaking = 0;
    for (final row in rows) {
      if (_dateOnly(row.read(_db.dailyTaskEvents.occurredAt)!) != today) {
        continue;
      }
      switch (DailyTaskType.parse(row.read(_db.dailyTaskEvents.taskType)!)) {
        case DailyTaskType.lesson:
          lesson += 1;
        case DailyTaskType.vocabularyReview:
          vocabularyReview += 1;
        case DailyTaskType.speaking:
          speaking += 1;
      }
    }
    return (
      lesson: lesson,
      vocabularyReview: vocabularyReview,
      speaking: speaking,
    );
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
