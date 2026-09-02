import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/assessment_attempt_tables.dart';
import 'tables/attempt_tables.dart';
import 'tables/content_versions_table.dart';
import 'tables/learner_tables.dart';
import 'tables/lesson_progress_tables.dart';
import 'tables/review_state_tables.dart';

part 'database.g.dart';

/// The local progress database — the source of truth for everything the app
/// renders about a learner's state.
///
/// Never stores curriculum content: content-reference columns (`unitId`,
/// `activityId`, `canDoId`, etc.) store the curriculum bundle's stable string
/// ids verbatim, never a Drift FK into mirrored content. See
/// docs/ARCHITECTURE.md and docs/DATA_MODEL.md.
@DriftDatabase(
  tables: [
    Learners,
    CourseEnrolments,
    UnitProgress,
    LessonProgress,
    ActivityAttempts,
    ActivityAttemptCanDos,
    PlacementAttempts,
    FinalMissionAttempts,
    FinalAssessmentAttempts,
    VocabularyReviewState,
    GrammarReviewState,
    ContentVersions,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Accepts an explicit executor — used by tests, which open an in-memory
  /// database instead of a file on disk.
  AppDatabase(super.executor);

  /// The real on-device database. Stored via drift_flutter's default
  /// application-documents-directory location.
  AppDatabase.defaults() : super(driftDatabase(name: 'mohingo_progress'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (migrator) => migrator.createAll());
}
