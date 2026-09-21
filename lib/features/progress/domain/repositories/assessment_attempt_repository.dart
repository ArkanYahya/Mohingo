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

  /// The learner's latest attempt at [courseId]'s final mission — never an
  /// attempt at another level's, which would read as this level's result
  /// under this level's heading.
  Future<FinalMissionAttempt?> latestFinalMissionAttempt({
    required int learnerId,
    required String courseId,
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

  /// The learner's latest attempt at [courseId]'s final assessment — see
  /// [latestFinalMissionAttempt] on why the course is part of the question.
  Future<FinalAssessmentAttempt?> latestFinalAssessmentAttempt({
    required int learnerId,
    required String courseId,
  });
}
