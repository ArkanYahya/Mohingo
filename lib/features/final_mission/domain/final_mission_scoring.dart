import '../../../content/models/capstone.dart';

/// One [FinalMission.requiredSkillGroups] bucket's result — never merged
/// into a single overall average with any other group, per the bundle's own
/// `noSingleAverageCompensation: true`. A group with any un-auto-gradable
/// (`notAutoGraded`) evidence is honestly reported as
/// [pendingReviewCount] > 0 rather than silently passed or failed — this
/// app has no rubric evaluator for free-response writing/speaking yet, see
/// docs/TECH_STACK.md.
class SkillGroupResult {
  const SkillGroupResult({
    required this.skills,
    required this.passed,
    required this.averageScore,
    required this.scoredEvidenceCount,
    required this.pendingReviewCount,
  });

  final List<String> skills;
  final bool passed;
  final double averageScore;
  final int scoredEvidenceCount;
  final int pendingReviewCount;
}

class FinalMissionScoringResult {
  const FinalMissionScoringResult({
    required this.groupResults,
    required this.passed,
  });

  final List<SkillGroupResult> groupResults;

  /// True only when every group independently clears
  /// [FinalMission.minimumCriterionScore] with fully scored evidence.
  final bool passed;
}

abstract final class FinalMissionScoring {
  /// [scoresBySkill] — for each attempted mission activity, its evidence
  /// skill (bundle skill string, e.g. `"listening"`) mapped to the score it
  /// achieved (`null` when the item couldn't be auto-graded).
  static FinalMissionScoringResult score({
    required FinalMission mission,
    required Map<String, List<double?>> scoresBySkill,
  }) {
    final groupResults = [
      for (final group in mission.requiredSkillGroups)
        _scoreGroup(mission, group, scoresBySkill),
    ];
    return FinalMissionScoringResult(
      groupResults: groupResults,
      passed: groupResults.every((g) => g.passed),
    );
  }

  static SkillGroupResult _scoreGroup(
    FinalMission mission,
    List<String> group,
    Map<String, List<double?>> scoresBySkill,
  ) {
    final allResults = [for (final skill in group) ...?scoresBySkill[skill]];
    final scored = [for (final s in allResults) ?s];
    final pendingCount = allResults.length - scored.length;

    final average = scored.isEmpty
        ? 0.0
        : scored.reduce((a, b) => a + b) / scored.length;
    final passed =
        pendingCount == 0 &&
        scored.isNotEmpty &&
        average >= mission.minimumCriterionScore;

    return SkillGroupResult(
      skills: group,
      passed: passed,
      averageScore: average,
      scoredEvidenceCount: scored.length,
      pendingReviewCount: pendingCount,
    );
  }
}
