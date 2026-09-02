import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// Vocabulary/chunk review state for one learner. Created lazily on first
/// favourite/review-queue encounter — not pre-populated for every lexicon and
/// chunk record at enrolment. Exactly one of [lexiconId]/[chunkId] is set.
/// [confidenceMarker] never grants course mastery by itself — that's tracked
/// separately via mastery evidence. See docs/DATA_MODEL.md.
class VocabularyReviewState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get lexiconId => text().nullable()();
  TextColumn get chunkId => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get confidenceMarker => text().nullable()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Grammar registry review state for one learner. [markedReviewedAt] is a
/// UI-only checkbox — it never flips any related Can-Do objective's mastered
/// state. See docs/DATA_MODEL.md.
class GrammarReviewState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get grammarId => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get markedReviewedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}
