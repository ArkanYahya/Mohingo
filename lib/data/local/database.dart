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
import 'tables/sync_tables.dart';

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
    SyncOutbox,
    AccountSyncStates,
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
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      for (final statement in syncTriggerStatements()) {
        await customStatement(statement);
      }
    },
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
      if (from < 6) {
        // Every real install has every table by now; the guard only spares
        // hand-built upgrade fixtures that model an older install with just
        // the tables their own step touches.
        final existing = {
          for (final row in await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ).get())
            row.read<String>('name'),
        };
        // SQLite can't ADD COLUMN ... UNIQUE, so the uniqueness of
        // firebase_uid comes from an index instead — the same guarantee.
        await customStatement(
          'ALTER TABLE learners ADD COLUMN firebase_uid TEXT NULL',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS learners_firebase_uid '
          'ON learners (firebase_uid)',
        );
        await migrator.addColumn(learners, learners.updatedAt);
        if (existing.contains('vocabulary_review_state')) {
          await migrator.addColumn(
            vocabularyReviewState,
            vocabularyReviewState.favoriteUpdatedAt,
          );
        }
        if (existing.contains('grammar_review_state')) {
          await migrator.addColumn(
            grammarReviewState,
            grammarReviewState.favoriteUpdatedAt,
          );
        }
        await migrator.createTable(syncOutbox);
        await migrator.createTable(accountSyncStates);
        for (final statement in syncTriggerStatements(existing.contains)) {
          await customStatement(statement);
        }
        // Progress recorded before accounts existed is queued like any new
        // write, so attaching it to an account later uploads all of it.
        for (final table in syncedLearnerTables.where(existing.contains)) {
          await customStatement(
            'INSERT INTO sync_outbox (entity, row_id, learner_id) '
            "SELECT '$table', id, learner_id FROM $table",
          );
        }
        await customStatement(
          'INSERT INTO sync_outbox (entity, row_id, learner_id) '
          "SELECT 'learners', id, id FROM learners WHERE name IS NOT NULL",
        );
      }
      if (from < 7) {
        // ADR 0011: the refinement queue carries the meaning signal and
        // whether the row may go online. An install coming from before v3
        // just had the table created in its current shape by the v3 step,
        // and a hand-built fixture may lack the table altogether, so each
        // column is added only where it is genuinely missing.
        final hasQueue = (await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'pending_online_refinements'",
        ).get()).isNotEmpty;
        if (hasQueue) {
          final columns = {
            for (final row in await customSelect(
              'PRAGMA table_info(pending_online_refinements)',
            ).get())
              row.read<String>('name'),
          };
          if (!columns.contains('meaning_signal')) {
            await migrator.addColumn(
              pendingOnlineRefinements,
              pendingOnlineRefinements.meaningSignal,
            );
          }
          if (!columns.contains('online_allowed')) {
            await migrator.addColumn(
              pendingOnlineRefinements,
              pendingOnlineRefinements.onlineAllowed,
            );
          }
        }
      }
    },
  );

  /// Every table whose rows are a learner's progress and are synced to
  /// their account. `unit_progress` is absent on purpose: it is recomputed
  /// from `activity_attempts`, so syncing the evidence is enough.
  /// `activity_attempt_can_dos` travels inside its attempt.
  static const syncedLearnerTables = [
    'activity_attempts',
    'lesson_progress',
    'vocabulary_review_state',
    'grammar_review_state',
    'course_enrolments',
    'placement_attempts',
    'final_mission_attempts',
    'final_assessment_attempts',
    'daily_task_events',
  ];

  /// The triggers that feed [SyncOutbox]: every insert or update of a synced
  /// row enqueues it, and so does a learner's name change. Idempotent, so
  /// safe to run on both create and upgrade. [include] limits it to the
  /// tables that exist (see the v6 upgrade).
  static List<String> syncTriggerStatements([
    bool Function(String table)? include,
  ]) => [
    for (final table in syncedLearnerTables.where(include ?? (_) => true))
      for (final event in const ['INSERT', 'UPDATE'])
        'CREATE TRIGGER IF NOT EXISTS sync_outbox_${table}_${event.toLowerCase()} '
            'AFTER $event ON $table BEGIN '
            'INSERT INTO sync_outbox (entity, row_id, learner_id) '
            "VALUES ('$table', NEW.id, NEW.learner_id); END",
    'CREATE TRIGGER IF NOT EXISTS sync_outbox_learners_name '
        'AFTER UPDATE OF name ON learners BEGIN '
        'INSERT INTO sync_outbox (entity, row_id, learner_id) '
        "VALUES ('learners', NEW.id, NEW.id); END",
  ];

  /// Erases every progress row for [learnerId] — mastery evidence, attempt
  /// history (lesson/placement/mission/assessment alike), vocabulary/grammar
  /// review state (including favourites), the course enrolment record
  /// (idempotently re-created on next app read, see
  /// `ensureLevelEnrolmentProvider`), any still-queued
  /// `PendingOnlineRefinements` items (a queued-but-unresolved answer is
  /// progress state too), and `DailyTaskEvents` (Home's "Tasks today" row
  /// resets with everything else). The `Learners` row itself, its stable
  /// UUID, and
  /// `content_versions` (a course-level log, not learner-level) are
  /// untouched — this resets a learner's *progress*, not their identity.
  /// Queued uploads of the erased rows go too: a reset is never followed by
  /// an upload of what it erased. (Telling the learner's *account* about the
  /// reset is the sync layer's job — `ProgressResetService`.)
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
      await (delete(
        syncOutbox,
      )..where((t) => t.learnerId.equals(learnerId))).go();
    });
  }
}
