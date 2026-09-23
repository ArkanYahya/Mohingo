import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:uuid/uuid.dart';

void main() {
  // This file intentionally opens more than one AppDatabase instance per
  // process (each migration test opens its own upgraded instance alongside
  // the `setUp` one) — never against the same executor, so there's no real
  // race. See https://drift.simonbinder.eu/faq/#using-the-database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version is 6', () {
    expect(database.schemaVersion, 6);
  });

  test('a v5 install upgrades to 6: existing progress is kept, belongs to '
      'the guest, and is queued so attaching it to an account uploads it', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
        CREATE TABLE learners (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          name TEXT NULL,
          native_language TEXT NOT NULL DEFAULT 'ar',
          target_language TEXT NOT NULL DEFAULT 'en',
          created_at INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
    raw.execute('''
        CREATE TABLE activity_attempts (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          learner_id INTEGER NOT NULL REFERENCES learners (id),
          activity_id TEXT NOT NULL,
          lesson_id TEXT NULL,
          session_type TEXT NOT NULL,
          session_id TEXT NULL,
          mode TEXT NOT NULL,
          evidence_skill TEXT NOT NULL,
          raw_answer TEXT NULL,
          is_correct INTEGER NULL,
          score REAL NULL,
          criteria_scores TEXT NULL,
          was_fallback INTEGER NOT NULL DEFAULT 0,
          attempted_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    raw.execute('''
        CREATE TABLE vocabulary_review_state (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          learner_id INTEGER NOT NULL REFERENCES learners (id),
          lexicon_id TEXT NULL,
          chunk_id TEXT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          confidence_marker TEXT NULL,
          ease_factor REAL NOT NULL DEFAULT 2.5,
          interval_days INTEGER NOT NULL DEFAULT 0,
          repetitions INTEGER NOT NULL DEFAULT 0,
          due_at INTEGER NULL,
          last_reviewed_at INTEGER NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    raw.execute(
      "INSERT INTO learners (uuid, name, created_at) VALUES ('l-1', 'Ali', 0)",
    );
    raw.execute(
      "INSERT INTO activity_attempts (uuid, learner_id, activity_id, "
      "session_type, mode, evidence_skill, attempted_at, updated_at) "
      "VALUES ('a-1', 1, 'A1-U1-L1-A01', 'lesson', 'mastery', 'reading', 0, 0)",
    );
    raw.execute(
      "INSERT INTO vocabulary_review_state (uuid, learner_id, lexicon_id, "
      "is_favorite, updated_at) VALUES ('v-1', 1, 'lex-1', 1, 0)",
    );
    raw.execute('PRAGMA user_version = 5');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final learner = await upgraded.select(upgraded.learners).getSingle();
    expect(learner.name, 'Ali');
    expect(
      learner.firebaseUid,
      isNull,
      reason: 'existing progress is the guest\'s',
    );
    final word = await upgraded
        .select(upgraded.vocabularyReviewState)
        .getSingle();
    expect(word.isFavorite, isTrue);
    expect(word.favoriteUpdatedAt, isNull);

    final queued = await upgraded.select(upgraded.syncOutbox).get();
    expect(
      {for (final e in queued) e.entity},
      {'activity_attempts', 'vocabulary_review_state', 'learners'},
    );

    // The triggers are live after the upgrade: a new answer is queued too.
    await upgraded
        .into(upgraded.activityAttempts)
        .insert(
          ActivityAttemptsCompanion.insert(
            uuid: 'a-2',
            learnerId: learner.id,
            activityId: 'A1-U1-L1-A02',
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'reading',
            attemptedAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    expect(await upgraded.select(upgraded.syncOutbox).get(), hasLength(4));

    // An account owns at most one learner row.
    await (upgraded.update(upgraded.learners)
          ..where((t) => t.id.equals(learner.id)))
        .write(const LearnersCompanion(firebaseUid: Value('uid-1')));
    await expectLater(
      upgraded
          .into(upgraded.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'l-2',
              createdAt: DateTime.utc(2026),
              firebaseUid: const Value('uid-1'),
            ),
          ),
      throwsA(isA<sqlite3.SqliteException>()),
    );
  });

  test('every insert or update of synced progress is queued for upload, '
      'and a reset clears the queue with the progress', () async {
    final learner = await upgradedLearner(database);
    await database
        .into(database.dailyTaskEvents)
        .insert(
          DailyTaskEventsCompanion.insert(
            uuid: 'd-1',
            learnerId: learner,
            taskType: 'lesson',
            occurredAt: DateTime.utc(2026),
          ),
        );
    await (database.update(database.learners)
          ..where((t) => t.id.equals(learner)))
        .write(const LearnersCompanion(isActive: Value(false)));
    final queued = await database.select(database.syncOutbox).get();
    expect(
      [for (final e in queued) e.entity],
      ['daily_task_events'],
      reason: 'switching the active learner is not progress',
    );

    await database.resetProgressForLearner(learner);
    expect(await database.select(database.syncOutbox).get(), isEmpty);
  });

  test('migrating from schemaVersion 1 adds a nullable name column without '
      'losing existing rows', () async {
    // Build a v1-shaped `learners` table by hand — v1 never had a `name`
    // column — then set drift's own version marker to 1, so opening it
    // through AppDatabase runs onUpgrade exactly like a real upgrading
    // install would.
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
        CREATE TABLE learners (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          native_language TEXT NOT NULL DEFAULT 'ar',
          target_language TEXT NOT NULL DEFAULT 'en',
          created_at INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
    // A genuine v1 install already has course_enrolments (unchanged in
    // shape since v1) — present here so the from < 5 branch, which alters
    // it, has a table to alter, exactly like a real upgrading install.
    raw.execute('''
        CREATE TABLE course_enrolments (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          learner_id INTEGER NOT NULL REFERENCES learners (id),
          course_id TEXT NOT NULL,
          content_version TEXT NOT NULL,
          enrolled_at INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');
    raw.execute(
      "INSERT INTO learners (uuid, created_at) VALUES ('learner-1', 0)",
    );
    raw.execute('PRAGMA user_version = 1');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final row = await upgraded.select(upgraded.learners).getSingle();
    expect(row.uuid, 'learner-1');
    expect(row.name, isNull);

    await (upgraded.update(upgraded.learners)
          ..where((t) => t.id.equals(row.id)))
        .write(const LearnersCompanion(name: Value('Ali')));
    final updated = await (upgraded.select(
      upgraded.learners,
    )..where((t) => t.id.equals(row.id))).getSingle();
    expect(updated.name, 'Ali');
  });

  test('a real v1 install jumping straight to schemaVersion 4 applies all '
      'three migrations, in order: the name column is added, the '
      'pending_online_refinements table is created, AND the '
      'daily_task_events table is created', () async {
    // Same v1-shaped `learners` table (no `name` column) as the test
    // above — this is what a genuine v1 install's on-disk schema looks
    // like. Nothing about the existing `from < 2` branch changes here;
    // this only proves it still fires correctly when `to` is 3, not 2.
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
          CREATE TABLE learners (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            native_language TEXT NOT NULL DEFAULT 'ar',
            target_language TEXT NOT NULL DEFAULT 'en',
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
    // A genuine v1 install already has course_enrolments (unchanged in
    // shape since v1) — present here so the from < 5 branch, which alters
    // it, has a table to alter, exactly like a real upgrading install.
    raw.execute('''
          CREATE TABLE course_enrolments (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            learner_id INTEGER NOT NULL REFERENCES learners (id),
            course_id TEXT NOT NULL,
            content_version TEXT NOT NULL,
            enrolled_at INTEGER NOT NULL,
            status TEXT NOT NULL
          )
        ''');
    raw.execute(
      "INSERT INTO learners (uuid, created_at) VALUES ('learner-1', 0)",
    );
    raw.execute('PRAGMA user_version = 1');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    // from < 2 branch: the name column exists and is nullable.
    final row = await upgraded.select(upgraded.learners).getSingle();
    expect(row.uuid, 'learner-1');
    expect(row.name, isNull);

    // from < 3 branch: the new queue table exists and is usable.
    await upgraded
        .into(upgraded.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: row.id,
            activityId: 'A1-U5-L6-A05',
            lessonId: 'A1-U5-L6',
            unitId: 'A1-U5',
            canDoIds: '[]',
            rawAnswer: 'answer',
            evidenceSkill: 'writing',
            mode: 'mastery',
            localScore: 0.0,
            submittedAt: DateTime.utc(2026, 9, 8),
          ),
        );
    final pending = await upgraded
        .select(upgraded.pendingOnlineRefinements)
        .get();
    expect(pending, hasLength(1));
    expect(pending.single.learnerId, row.id);

    // from < 4 branch: the new daily-task-events table exists and is
    // usable.
    await upgraded
        .into(upgraded.dailyTaskEvents)
        .insert(
          DailyTaskEventsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: row.id,
            taskType: 'lesson',
            occurredAt: DateTime.utc(2026, 9, 10),
          ),
        );
    final dailyTaskEvents = await upgraded
        .select(upgraded.dailyTaskEvents)
        .get();
    expect(dailyTaskEvents, hasLength(1));
    expect(dailyTaskEvents.single.learnerId, row.id);
  });

  test('a v4 install upgrades to 5: an existing enrolment keeps its data and '
      'gains the three nullable level columns', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
          CREATE TABLE learners (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            name TEXT NULL,
            native_language TEXT NOT NULL DEFAULT 'ar',
            target_language TEXT NOT NULL DEFAULT 'en',
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
    raw.execute('''
          CREATE TABLE course_enrolments (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            learner_id INTEGER NOT NULL REFERENCES learners (id),
            course_id TEXT NOT NULL,
            content_version TEXT NOT NULL,
            enrolled_at INTEGER NOT NULL,
            status TEXT NOT NULL
          )
        ''');
    raw.execute(
      "INSERT INTO learners (uuid, created_at) VALUES ('learner-1', 0)",
    );
    raw.execute(
      "INSERT INTO course_enrolments "
      "(uuid, learner_id, course_id, content_version, enrolled_at, status) "
      "VALUES ('e-1', 1, 'EN-A1-V2', 'A1-COMPLETE-2026.09.02', 0, 'active')",
    );
    raw.execute('PRAGMA user_version = 4');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final row = await upgraded.select(upgraded.courseEnrolments).getSingle();
    expect(row.courseId, 'EN-A1-V2');
    expect(row.levelId, isNull);
    expect(row.lastSelectedAt, isNull);
    expect(row.unlockedAt, isNull);

    // The new columns are writable, not just present.
    await (upgraded.update(
      upgraded.courseEnrolments,
    )..where((t) => t.id.equals(row.id))).write(
      CourseEnrolmentsCompanion(
        levelId: const Value('a1'),
        lastSelectedAt: Value(DateTime.utc(2026, 9, 20)),
        unlockedAt: Value(DateTime.utc(2026, 9, 20)),
      ),
    );
    final updated = await upgraded
        .select(upgraded.courseEnrolments)
        .getSingle();
    expect(updated.levelId, 'a1');
    // Compared via toUtc(): drift round-trips DateTimeColumn values as unix
    // timestamps and hands them back in local time (same instant, different
    // `isUtc` flag) — and Dart's DateTime equality treats that flag as
    // significant, so a raw `==` against a UTC literal is timezone-dependent
    // even though the underlying instant matches exactly.
    expect(updated.lastSelectedAt?.toUtc(), DateTime.utc(2026, 9, 20));
    expect(updated.unlockedAt?.toUtc(), DateTime.utc(2026, 9, 20));
  });

  test('can insert and read back a learner, with ar/en defaults', () async {
    final uuid = const Uuid().v4();
    await database
        .into(database.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: uuid,
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final rows = await database.select(database.learners).get();
    expect(rows, hasLength(1));
    expect(rows.single.uuid, uuid);
    expect(rows.single.nativeLanguage, 'ar');
    expect(rows.single.targetLanguage, 'en');
    expect(rows.single.isActive, isTrue);
  });

  test(
    'activity_attempts is insert-only: a replay appends, not overwrites',
    () async {
      final learnerId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      Future<int> recordAttempt() => database
          .into(database.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U1-L1-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await recordAttempt();
      await recordAttempt(); // a replay of the same activity

      final rows = await (database.select(
        database.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U1-L1-A01'))).get();
      expect(
        rows,
        hasLength(2),
        reason: 'a replay must append, never overwrite',
      );
    },
  );

  test('activity_attempt_can_dos normalizes an attempt\'s canDo ids', () async {
    final learnerId = await database
        .into(database.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final attemptId = await database
        .into(database.activityAttempts)
        .insert(
          ActivityAttemptsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U1-L1-A01',
            sessionType: 'lesson',
            mode: 'mastery',
            evidenceSkill: 'listening',
            attemptedAt: DateTime.utc(2026, 9, 2),
            updatedAt: DateTime.utc(2026, 9, 2),
          ),
        );

    await database
        .into(database.activityAttemptCanDos)
        .insert(
          ActivityAttemptCanDosCompanion.insert(
            attemptId: attemptId,
            canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
          ),
        );

    final joined = await (database.select(
      database.activityAttemptCanDos,
    )..where((t) => t.attemptId.equals(attemptId))).get();
    expect(joined, hasLength(1));
    expect(joined.single.canDoId, 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO');
  });

  test(
    'a speaking fallback is recorded as writing evidence, not speaking',
    () async {
      final learnerId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await database
          .into(database.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L1-A04',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing', // fallback, not spokenProduction
              wasFallback: const Value(true),
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      final rows = await (database.select(
        database.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L1-A04'))).get();
      expect(rows.single.wasFallback, isTrue);
      expect(rows.single.evidenceSkill, 'writing');
    },
  );

  group('resetProgressForLearner', () {
    test('erases every progress row for the learner across every table, '
        'never touches another learner\'s data, and preserves the Learners '
        'row itself (identity, not progress)', () async {
      final learnerAId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-a',
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );
      final learnerBId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-b',
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );

      Future<void> seedFor(int learnerId) async {
        await database
            .into(database.courseEnrolments)
            .insert(
              CourseEnrolmentsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                courseId: 'EN-A1-V2',
                contentVersion: 'v1',
                enrolledAt: DateTime.utc(2026, 9, 2),
                status: 'active',
              ),
            );
        await database
            .into(database.unitProgress)
            .insert(
              UnitProgressCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                unitId: 'A1-U1',
                state: 'inProgress',
                updatedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.lessonProgress)
            .insert(
              LessonProgressCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                lessonId: 'A1-U1-L1',
                unitId: 'A1-U1',
                state: 'inProgress',
                updatedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        final attemptId = await database
            .into(database.activityAttempts)
            .insert(
              ActivityAttemptsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                activityId: 'A1-U1-L1-A01',
                sessionType: 'lesson',
                mode: 'mastery',
                evidenceSkill: 'listening',
                attemptedAt: DateTime.utc(2026, 9, 2),
                updatedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.activityAttemptCanDos)
            .insert(
              ActivityAttemptCanDosCompanion.insert(
                attemptId: attemptId,
                canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
              ),
            );
        await database
            .into(database.placementAttempts)
            .insert(
              PlacementAttemptsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                startedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.finalMissionAttempts)
            .insert(
              FinalMissionAttemptsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                courseId: 'EN-A1-V2',
                startedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.finalAssessmentAttempts)
            .insert(
              FinalAssessmentAttemptsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                courseId: 'EN-A1-V2',
                startedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.vocabularyReviewState)
            .insert(
              VocabularyReviewStateCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                lexiconId: const Value('A1.LEX.WORD.N01'),
                isFavorite: const Value(true),
                updatedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.grammarReviewState)
            .insert(
              GrammarReviewStateCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                grammarId: 'A1.GRAM.PRESENT_SIMPLE',
                isFavorite: const Value(true),
                updatedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.pendingOnlineRefinements)
            .insert(
              PendingOnlineRefinementsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                activityId: 'A1-U5-L6-A05',
                lessonId: 'A1-U5-L6',
                unitId: 'A1-U5',
                canDoIds: '[]',
                rawAnswer: 'answer',
                evidenceSkill: 'writing',
                mode: 'mastery',
                localScore: 0.5,
                submittedAt: DateTime.utc(2026, 9, 2),
              ),
            );
        await database
            .into(database.dailyTaskEvents)
            .insert(
              DailyTaskEventsCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                taskType: 'lesson',
                occurredAt: DateTime.utc(2026, 9, 2),
              ),
            );
      }

      await seedFor(learnerAId);
      await seedFor(learnerBId);

      await database.resetProgressForLearner(learnerAId);

      // Learner A: every progress table is empty.
      for (final rows in [
        await (database.select(
          database.courseEnrolments,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.unitProgress,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.lessonProgress,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.activityAttempts,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.placementAttempts,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.finalMissionAttempts,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.finalAssessmentAttempts,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.vocabularyReviewState,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.grammarReviewState,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.pendingOnlineRefinements,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
        await (database.select(
          database.dailyTaskEvents,
        )..where((t) => t.learnerId.equals(learnerAId))).get(),
      ]) {
        expect(rows, isEmpty);
      }
      expect(
        await database.select(database.activityAttemptCanDos).get(),
        hasLength(1),
        reason:
            'learner A\'s can-do link must go with its attempt, but '
            'learner B\'s own attempt/link (seeded separately) must survive',
      );

      // Learner B: completely untouched.
      expect(
        await (database.select(
          database.unitProgress,
        )..where((t) => t.learnerId.equals(learnerBId))).get(),
        hasLength(1),
      );
      expect(
        await (database.select(
          database.vocabularyReviewState,
        )..where((t) => t.learnerId.equals(learnerBId))).get(),
        hasLength(1),
      );
      expect(
        await (database.select(
          database.pendingOnlineRefinements,
        )..where((t) => t.learnerId.equals(learnerBId))).get(),
        hasLength(1),
      );
      expect(
        await (database.select(
          database.dailyTaskEvents,
        )..where((t) => t.learnerId.equals(learnerBId))).get(),
        hasLength(1),
      );

      // Both Learners rows themselves are preserved — reset erases
      // progress, not identity.
      final learners = await database.select(database.learners).get();
      expect(learners.map((l) => l.id).toSet(), {learnerAId, learnerBId});
    });
  });

  group('pendingOnlineRefinements', () {
    test('can insert and read back a queued refinement', () async {
      final learnerId = await database
          .into(database.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 8),
            ),
          );

      await database
          .into(database.pendingOnlineRefinements)
          .insert(
            PendingOnlineRefinementsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U5-L6-A05',
              lessonId: 'A1-U5-L6',
              unitId: 'A1-U5',
              canDoIds: '["A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE"]',
              rawAnswer: 'See you at the park on Saturday!',
              evidenceSkill: 'writing',
              mode: 'mastery',
              localScore: 0.5,
              submittedAt: DateTime.utc(2026, 9, 8),
            ),
          );

      final rows = await database
          .select(database.pendingOnlineRefinements)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.activityId, 'A1-U5-L6-A05');
      expect(rows.single.attemptCount, 0);
      expect(rows.single.lastAttemptAt, isNull);
    });
  });
}

Future<int> upgradedLearner(AppDatabase db) => db
    .into(db.learners)
    .insert(
      LearnersCompanion.insert(uuid: 'l-x', createdAt: DateTime.utc(2026)),
    );
