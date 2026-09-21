import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_assessment_attempt_repository.dart';

void main() {
  late AppDatabase db;
  late DriftAssessmentAttemptRepository repo;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftAssessmentAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
  });

  tearDown(() => db.close());

  group('placement attempts', () {
    test('start/complete round-trips through latestPlacementAttempt', () async {
      final attemptId = await repo.startPlacementAttempt(
        learnerId: learnerId,
        itemSamplingSeed: '123',
      );
      await repo.completePlacementAttempt(
        attemptId: attemptId,
        stageReached: 4,
        outcome: 'startFromRecommendedUnit',
        recommendedUnitId: 'A1-U4',
        confidenceSelfReportsJson: '{"overall":3}',
      );

      final latest = await repo.latestPlacementAttempt(learnerId: learnerId);
      expect(latest, isNotNull);
      expect(latest!.outcome, 'startFromRecommendedUnit');
      expect(latest.recommendedUnitId, 'A1-U4');
      expect(latest.stageReached, 4);
      expect(latest.completedAt, isNotNull);
    });

    test('a retake is stored as a separate row, not overwritten — each '
        'attempt keeps its own itemSamplingSeed', () async {
      final firstId = await repo.startPlacementAttempt(
        learnerId: learnerId,
        itemSamplingSeed: 'seed-1',
      );
      await repo.completePlacementAttempt(
        attemptId: firstId,
        stageReached: 1,
        outcome: 'startWithEssentials',
      );

      final secondId = await repo.startPlacementAttempt(
        learnerId: learnerId,
        itemSamplingSeed: 'seed-2',
      );
      await repo.completePlacementAttempt(
        attemptId: secondId,
        stageReached: 13,
        outcome: 'a1Mastered',
      );

      final allAttempts = await db.select(db.placementAttempts).get();
      expect(allAttempts, hasLength(2));
      expect(allAttempts.map((a) => a.itemSamplingSeed).toSet(), {
        'seed-1',
        'seed-2',
      });
      expect(firstId, isNot(secondId));

      final latest = await repo.latestPlacementAttempt(learnerId: learnerId);
      expect(latest!.id, secondId);
      expect(latest.outcome, 'a1Mastered');
    });
  });

  group('final mission attempts', () {
    test(
      'start/complete round-trips through latestFinalMissionAttempt',
      () async {
        final attemptId = await repo.startFinalMissionAttempt(
          learnerId: learnerId,
          courseId: 'EN-A1-V2',
        );
        await repo.completeFinalMissionAttempt(
          attemptId: attemptId,
          stagesCompletedJson: '["stage-1","stage-2"]',
          outcome: 'passed',
        );

        final latest = await repo.latestFinalMissionAttempt(
          learnerId: learnerId,
          courseId: 'EN-A1-V2',
        );
        expect(latest, isNotNull);
        expect(latest!.outcome, 'passed');
        expect(latest.completedAt, isNotNull);
      },
    );

    test('the latest attempt is the latest attempt at THAT course — a '
        'learner who finished A1 and moved to A2 has not attempted A2\'s '
        'mission', () async {
      final a1 = await repo.startFinalMissionAttempt(
        learnerId: learnerId,
        courseId: 'EN-A1-V2',
      );
      await repo.completeFinalMissionAttempt(
        attemptId: a1,
        stagesCompletedJson: '[]',
        outcome: 'passed',
      );

      expect(
        await repo.latestFinalMissionAttempt(
          learnerId: learnerId,
          courseId: 'EN-A2-V1',
        ),
        isNull,
      );
      expect(
        (await repo.latestFinalMissionAttempt(
          learnerId: learnerId,
          courseId: 'EN-A1-V2',
        ))!.id,
        a1,
      );
    });
  });

  group('final assessment attempts', () {
    test(
      'start/complete round-trips through latestFinalAssessmentAttempt',
      () async {
        final attemptId = await repo.startFinalAssessmentAttempt(
          learnerId: learnerId,
          courseId: 'EN-A1-V2',
        );
        await repo.completeFinalAssessmentAttempt(
          attemptId: attemptId,
          sectionResultsJson: '[{"section":"listening","status":"passed"}]',
          outcomeSummaryJson: '{"overallPassed":false}',
        );

        final latest = await repo.latestFinalAssessmentAttempt(
          learnerId: learnerId,
          courseId: 'EN-A1-V2',
        );
        expect(latest, isNotNull);
        expect(latest!.outcomeSummary, contains('overallPassed'));
        expect(latest.completedAt, isNotNull);
      },
    );

    test('and an A1 assessment is not A2\'s latest either', () async {
      await repo.startFinalAssessmentAttempt(
        learnerId: learnerId,
        courseId: 'EN-A1-V2',
      );

      expect(
        await repo.latestFinalAssessmentAttempt(
          learnerId: learnerId,
          courseId: 'EN-A2-V1',
        ),
        isNull,
      );
    });
  });
}
