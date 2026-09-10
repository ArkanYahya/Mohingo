import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// One row per completed "task today" moment — a lesson finishing, a
/// vocabulary word being reviewed, or a speaking activity being submitted.
///
/// **Insert-only**, mirroring [ActivityAttempts]: never updated or
/// deduplicated at write time, since Home only ever reads *counts* for the
/// current calendar day (see `DailyTaskEventRepository.countsForToday`).
/// [taskType] is `lesson` | `vocabularyReview` | `speaking`. See
/// docs/DATA_MODEL.md.
class DailyTaskEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get taskType => text()();
  DateTimeColumn get occurredAt => dateTime()();
}
