import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/assessment_attempt_tables.dart';
import 'tables/attempt_tables.dart';
import 'tables/content_versions_table.dart';
import 'tables/daily_task_event_tables.dart';
import 'tables/learner_tables.dart';
import 'tables/lesson_progress_tables.dart';
import 'tables/pending_online_refinement_tables.dart';
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
    PendingOnlineRefinements,
    DailyTaskEvents,
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
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(learners, learners.name);
      }
      if (from < 3) {
        await migrator.createTable(pendingOnlineRefinements);
      }
      if (from < 4) {
        await migrator.createTable(dailyTaskEvents);
      }
      if (from < 5) {
        await migrator.addColumn(courseEnrolments, courseEnrolments.levelId);
        await migrator.addColumn(
          courseEnrolments,
          courseEnrolments.lastSelectedAt,
        );
        await migrator.addColumn(courseEnrolments, courseEnrolments.unlockedAt);
      }
    },
  );

  /// Erases every progress row for [learnerId] — mastery evidence, attempt
  /// history (lesson/placement/mission/assessment alike), vocabulary/grammar
  /// review state (including favourites), the course enrolment record
  /// (idempotently re-created on next app read, see
  /// `ensureA1EnrollmentProvider`), any still-queued
  /// `PendingOnlineRefinements` items (a queued-but-unresolved answer is
  /// progress state too), and `DailyTaskEvents` (Home's "Tasks today" row
  /// resets with everything else). The `Learners` row itself, its stable
  /// UUID, and
  /// `content_versions` (a course-level log, not learner-level) are
  /// untouched — this resets a learner's *progress*, not their identity.
  /// See docs/UX_PRINCIPLES.md's "resetting progress" confirmation-copy rule
  /// and docs/DATA_MODEL.md.
  Future<void> resetProgressForLearner(int learnerId) {
    return transaction(() async {
      final attemptIds =
          await (selectOnly(activityAttempts)
                ..addColumns([activityAttempts.id])
                ..where(activityAttempts.learnerId.equals(learnerId)))
              .map((row) => row.read(activityAttempts.id)!)
              .get();
      if (attemptIds.isNotEmpty) {
        await (delete(
          activityAttemptCanDos,
        )..where((t) => t.attemptId.isIn(attemptIds))).go();
      }
      await (delete(
        activityAttempts,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        unitProgress,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        lessonProgress,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        placementAttempts,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        finalMissionAttempts,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        finalAssessmentAttempts,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        vocabularyReviewState,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        grammarReviewState,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        courseEnrolments,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        pendingOnlineRefinements,
      )..where((t) => t.learnerId.equals(learnerId))).go();
      await (delete(
        dailyTaskEvents,
      )..where((t) => t.learnerId.equals(learnerId))).go();
    });
  }
}
