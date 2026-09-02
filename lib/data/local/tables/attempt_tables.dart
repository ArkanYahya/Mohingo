import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// One row per attempt at a curriculum activity (or a placement/final-mission/
/// final-assessment item, which share this table via [sessionType]).
///
/// **Insert-only, never updated** — a replayed activity appends a new row
/// rather than overwriting, so a learner revisiting a completed unit never
/// corrupts prior mastery history. [mode] is copied from the activity at
/// record time (not looked up later) so history stays self-describing even if
/// curriculum content changes in a future bundle version.
///
/// [evidenceSkill] normally equals the activity's declared skill; when a
/// `speak` activity is answered via its bundle-declared `fallbackSkill`
/// (typed-answer accessibility fallback), [wasFallback] is `true` and
/// [evidenceSkill] is set to the fallback skill — this is the concrete
/// mechanism that keeps a speaking fallback from ever counting as speaking
/// evidence. See docs/DATA_MODEL.md.
class ActivityAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get activityId => text()();
  TextColumn get lessonId =>
      text().nullable()(); // null for placement/mission/assessment items
  TextColumn get sessionType => text()(); // lesson | practiceReview | placement | finalMission | finalAssessment
  TextColumn get sessionId =>
      text().nullable()(); // links to the relevant attempt table's uuid
  TextColumn get mode => text()(); // encounter | practice | mastery
  TextColumn get evidenceSkill => text()();
  TextColumn get rawAnswer => text().nullable()(); // JSON
  BoolColumn get isCorrect => boolean().nullable()();
  RealColumn get score => real().nullable()();
  TextColumn get criteriaScores => text().nullable()(); // JSON
  BoolColumn get wasFallback => boolean().withDefault(const Constant(false))();
  DateTimeColumn get attemptedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Normalizes an activity's `canDo: [id]` array into one row per
/// (attempt x Can-Do objective) pair, so mastery aggregation is a single
/// indexed SQL join rather than per-row JSON scanning in Dart. See
/// docs/DATA_MODEL.md.
class ActivityAttemptCanDos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get attemptId => integer().references(ActivityAttempts, #id)();
  TextColumn get canDoId => text()();
}
