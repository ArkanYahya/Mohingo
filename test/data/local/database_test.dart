import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version is 1', () {
    expect(database.schemaVersion, 1);
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

      // Both Learners rows themselves are preserved — reset erases
      // progress, not identity.
      final learners = await database.select(database.learners).get();
      expect(learners.map((l) => l.id).toSet(), {learnerAId, learnerBId});
    });
  });
}
