import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// One row per A1 Gateway Placement Test attempt. Per-item results live in
/// `ActivityAttempts` filtered to `sessionType='placement'`. [outcome] is one
/// of the four actionable A1-only outcomes — this test never fabricates an
/// A2+ result. Kept as its own table (not folded into `CourseEnrolments`) so
/// retakes are isolated and item-answer state never leaks into ordinary
/// lesson Review. See docs/DATA_MODEL.md.
class PlacementAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get stageReached => integer().withDefault(const Constant(0))();
  TextColumn get outcome => text().nullable()();
  TextColumn get recommendedUnitId => text().nullable()();
  TextColumn get confidenceSelfReports =>
      text().nullable()(); // JSON, supporting-only, never the score
  TextColumn get itemSamplingSeed => text().nullable()();
}

/// One row per Final Mission attempt. Per-item results live in
/// `ActivityAttempts` filtered to `sessionType='finalMission'`. See
/// docs/DATA_MODEL.md.
class FinalMissionAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get courseId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get stagesCompleted => text().nullable()(); // JSON
  TextColumn get outcome => text().nullable()();
}

/// One row per Final Assessment attempt. Per-item results live in
/// `ActivityAttempts` filtered to `sessionType='finalAssessment'`. Kept
/// isolated so assessment answers never leak into ordinary lesson Review, per
/// the curriculum's own secure/unseen-inputs policy. See docs/DATA_MODEL.md.
class FinalAssessmentAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get courseId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get sectionResults => text().nullable()(); // JSON
  TextColumn get outcomeSummary =>
      text().nullable()(); // JSON, per-skill pass/fail — never one hiding score
}
