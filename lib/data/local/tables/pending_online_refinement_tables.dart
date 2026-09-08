import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// A submitted open-ended answer waiting for its free, online grammar-
/// quality pass — Tier 2 of docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
///
/// Deliberately **not** a row in `ActivityAttempts` (that table is
/// insert-only, evidence-of-record) — this is a mutable queue. Once an
/// item resolves (online refinement succeeds, or the bounded fallback in
/// [attemptCount]/[submittedAt] triggers), exactly one ordinary
/// `ActivityAttempts` row is inserted and this row is deleted. [canDoIds]
/// and [mode] are copied from the activity at enqueue time (denormalized,
/// like `ActivityAttempts.mode` already is) so resolving an item never
/// needs a fresh content-bundle lookup. [localScore] is the offline
/// `keywordChecklist` content score, computed once at submission time —
/// combined with the online grammar signal (or used alone, on fallback) to
/// produce the final score. See docs/DATA_MODEL.md.
class PendingOnlineRefinements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get activityId => text()();
  TextColumn get lessonId => text()();
  TextColumn get unitId => text()();
  TextColumn get canDoIds => text()(); // JSON-encoded List<String>
  TextColumn get rawAnswer => text()();
  TextColumn get evidenceSkill => text()();
  TextColumn get mode => text()(); // encounter | practice | mastery
  RealColumn get localScore => real()();
  DateTimeColumn get submittedAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
