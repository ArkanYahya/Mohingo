import 'package:collection/collection.dart';

import '../../../content/models/capstone.dart';

/// One [FinalAssessment] section's outcome. [pendingReview] (not
/// pass/fail) is reported whenever any item in the section couldn't be
/// auto-graded — this app has no rubric evaluator for free-response
/// writing/speaking/mediation yet, and the assessment's own
/// `noSingleOverallAverage` rule means a section is never averaged away or
/// guessed at. See docs/TECH_STACK.md and docs/DATA_MODEL.md.
enum FinalAssessmentSectionStatus { passed, notMet, pendingReview }

class FinalAssessmentSectionResult {
  const FinalAssessmentSectionResult({
    required this.section,
    required this.status,
    required this.averageScore,
    required this.scoredCount,
    required this.pendingReviewCount,
  });

  final String section;
  final FinalAssessmentSectionStatus status;
  final double averageScore;
  final int scoredCount;
  final int pendingReviewCount;
}

abstract final class FinalAssessmentScoring {
  /// [scoresBySection] — for each section key, one entry per attempted
  /// item (`null` when that item couldn't be auto-graded).
  static List<FinalAssessmentSectionResult> score({
    required FinalAssessment assessment,
    required Map<String, List<double?>> scoresBySection,
  }) {
    return [
      for (final sectionKey in assessment.sections.keys)
        _scoreSection(
          assessment,
          sectionKey,
          scoresBySection[sectionKey] ?? const [],
        ),
    ];
  }

  static FinalAssessmentSectionResult _scoreSection(
    FinalAssessment assessment,
    String sectionKey,
    List<double?> results,
  ) {
    final scored = [for (final r in results) ?r];
    final pendingCount = results.length - scored.length;

    if (pendingCount > 0 || scored.isEmpty) {
      return FinalAssessmentSectionResult(
        section: sectionKey,
        status: FinalAssessmentSectionStatus.pendingReview,
        averageScore: scored.isEmpty
            ? 0.0
            : scored.reduce((a, b) => a + b) / scored.length,
        scoredCount: scored.length,
        pendingReviewCount: pendingCount,
      );
    }

    final average = scored.reduce((a, b) => a + b) / scored.length;
    final threshold = assessment.minimumScoreForSection(sectionKey);
    return FinalAssessmentSectionResult(
      section: sectionKey,
      status: average >= threshold
          ? FinalAssessmentSectionStatus.passed
          : FinalAssessmentSectionStatus.notMet,
      averageScore: average,
      scoredCount: scored.length,
      pendingReviewCount: 0,
    );
  }

  /// [assessment.requiredSkills] never averaged into one score — every
  /// required section must independently reach [passed] for the
  /// assessment as a whole to pass. A section missing from [results]
  /// entirely (shouldn't happen against real content) counts as not
  /// passed rather than being skipped.
  static bool overallPassed(
    FinalAssessment assessment,
    List<FinalAssessmentSectionResult> results,
  ) {
    return assessment.requiredSkills.every((skill) {
      final result = results.where((r) => r.section == skill).firstOrNull;
      return result?.status == FinalAssessmentSectionStatus.passed;
    });
  }
}
