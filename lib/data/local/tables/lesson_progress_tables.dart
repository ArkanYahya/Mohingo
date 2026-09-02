import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// A read-model recomputed by the mastery-aggregation domain service from
/// [ActivityAttempts]/`ActivityAttemptCanDos` evidence rows — never
/// hand-edited directly by a UI action. Drives the Learn tab's unit-state
/// badges and Home's "Continue learning" resolution. [unitId] is the
/// curriculum bundle's stable string id (e.g. `"A1-U1"`), never a Drift FK
/// into mirrored content — see docs/DATA_MODEL.md.
///
/// [state] is a recommendation, not a hard lock: a learner may always
/// navigate to any unit regardless of this value — see docs/PRODUCT.md flow 5.
class UnitProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get unitId => text()();
  TextColumn get state =>
      text()(); // notStarted | inProgress | needsReview | mastered
  DateTimeColumn get lastActivityAt => dateTime().nullable()();
  DateTimeColumn get masteredAt => dateTime().nullable()();
  BoolColumn get isContentStale =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Backs "resume safely after being killed mid-lesson" — [lastActivityId] is
/// written after every meaningful event, not just at lesson end. See
/// docs/DATA_MODEL.md.
class LessonProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get lessonId => text()();
  TextColumn get unitId =>
      text()(); // denormalized for fast unit-scoped queries
  TextColumn get state => text()();
  TextColumn get lastActivityId => text().nullable()();
  DateTimeColumn get lastPositionUpdatedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}
