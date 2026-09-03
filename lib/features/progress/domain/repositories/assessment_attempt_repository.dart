import '../../../../data/local/database.dart';

/// Placement-test, Final-Mission, and Final-Assessment attempt bookkeeping.
///
/// Per-item results for all three live in [ActivityAttemptRepository],
/// filtered by `sessionType`; these tables hold one row per *attempt as a
/// whole* (started/completed/outcome). Kept as three separate concerns (not
/// folded into course enrolment) so retakes are isolated and — combined with
/// [ActivityAttemptRepository]'s `sessionType` filtering — assessment
/// answers never leak into ordinary lesson Review. See docs/DATA_MODEL.md.
abstract interface class AssessmentAttemptRepository {
  Future<int> startPlacementAttempt({
    required int learnerId,
    required String itemSamplingSeed,
  });

  Future<void> completePlacementAttempt({
    required int attemptId,
    required int stageReached,
    required String outcome,
    String? recommendedUnitId,
    String? confidenceSelfReportsJson,
  });

  Future<PlacementAttempt?> latestPlacementAttempt({required int learnerId});

  Future<int> startFinalMissionAttempt({
    required int learnerId,
    required String courseId,
  });

  Future<void> completeFinalMissionAttempt({
    required int attemptId,
    required String stagesCompletedJson,
    required String outcome,
  });

  Future<FinalMissionAttempt?> latestFinalMissionAttempt({
    required int learnerId,
  });

  Future<int> startFinalAssessmentAttempt({
    required int learnerId,
    required String courseId,
  });

  Future<void> completeFinalAssessmentAttempt({
    required int attemptId,
    required String sectionResultsJson,
    required String outcomeSummaryJson,
  });

  Future<FinalAssessmentAttempt?> latestFinalAssessmentAttempt({
    required int learnerId,
  });
}
