import 'activity.dart';

/// One stage of the [FinalMission] (e.g. "Register", "Meet People"),
/// grouping several activity ids.
class MissionStage {
  const MissionStage({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.activityIds,
  });

  factory MissionStage.fromJson(Map<String, dynamic> json) {
    return MissionStage(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      activityIds: List<String>.from(json['activityIds'] as List),
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final List<String> activityIds;
}

/// `A1-FINAL-MISSION` — a scenario-based capstone activity set, separate
/// from ordinary lesson training. See docs/GLOSSARY.md and
/// docs/DATA_MODEL.md.
class FinalMission {
  const FinalMission({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.scenario,
    required this.canDo,
    required this.stages,
    required this.activities,
    required this.requiredSkillGroups,
    required this.minimumCriterionScore,
    required this.noSingleAverageCompensation,
    required this.raw,
  });

  factory FinalMission.fromJson(Map<String, dynamic> json) {
    final scoring = json['scoring'] as Map<String, dynamic>;
    return FinalMission(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      scenario: json['scenario'] as String,
      canDo: List<String>.from(json['canDo'] as List),
      stages: (json['stages'] as List)
          .map((s) => MissionStage.fromJson(s as Map<String, dynamic>))
          .toList(),
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      requiredSkillGroups: (scoring['requiredSkillGroups'] as List)
          .map((g) => List<String>.from(g as List))
          .toList(),
      minimumCriterionScore: (scoring['minimumCriterionScore'] as num)
          .toDouble(),
      noSingleAverageCompensation:
          scoring['noSingleAverageCompensation'] as bool,
      raw: json,
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final String scenario;
  final List<String> canDo;
  final List<MissionStage> stages;
  final List<Activity> activities;
  final List<List<String>> requiredSkillGroups;
  final double minimumCriterionScore;
  final bool noSingleAverageCompensation;
  final Map<String, dynamic> raw;
}

/// One skill section of the [FinalAssessment] (e.g. `listening`, `writing`).
class AssessmentSection {
  const AssessmentSection({required this.activities, required this.raw});

  factory AssessmentSection.fromJson(Map<String, dynamic> json) {
    return AssessmentSection(
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      raw: json,
    );
  }

  final List<Activity> activities;

  /// Carries `targetEvidencePoints`/`targetTasks` and any other
  /// section-specific metadata.
  final Map<String, dynamic> raw;
}

/// `A1-FINAL-ASSESSMENT` — a summative exit test with secured, unseen items,
/// never drawn from training content. Scored per skill with no single
/// overall average hiding a failed essential skill — see
/// [requiredSkills]/[noSingleOverallAverage] and docs/DATA_MODEL.md.
class FinalAssessment {
  const FinalAssessment({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.sourcePolicy,
    required this.sections,
    required this.requiredSkills,
    required this.noSingleOverallAverage,
    required this.fallbackDoesNotCreateSpeakingEvidence,
    required this.raw,
  });

  factory FinalAssessment.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as Map<String, dynamic>;
    final scoring = json['scoring'] as Map<String, dynamic>;
    final decisionRule = scoring['decisionRule'] as Map<String, dynamic>;
    final accessibility = scoring['accessibility'] as Map<String, dynamic>;
    return FinalAssessment(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      sourcePolicy: json['sourcePolicy'] as String,
      sections: sectionsJson.map(
        (key, value) => MapEntry(
          key,
          AssessmentSection.fromJson(value as Map<String, dynamic>),
        ),
      ),
      requiredSkills: List<String>.from(decisionRule['required'] as List),
      noSingleOverallAverage: decisionRule['noSingleOverallAverage'] as bool,
      fallbackDoesNotCreateSpeakingEvidence:
          accessibility['fallbackDoesNotCreateSpeakingEvidence'] as bool,
      raw: json,
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final String sourcePolicy;
  final Map<String, AssessmentSection> sections;
  final List<String> requiredSkills;
  final bool noSingleOverallAverage;
  final bool fallbackDoesNotCreateSpeakingEvidence;
  final Map<String, dynamic> raw;

  List<Activity> get allActivities =>
      sections.values.expand((s) => s.activities).toList();

  /// The score threshold a section's scored-item average must clear to
  /// pass, read from this assessment's per-section `scoring` config —
  /// `receptive.minimumPerSkill` for `listening`/`reading`,
  /// `writing.minimumTaskCriterionAverage`,
  /// `speaking.minimumTaskCriterionAverage`,
  /// `mediation.minimumCriterionAverage`. Falls back to the domain's 0.6
  /// A1 baseline if a section's own field is ever absent — never throws,
  /// since a missing threshold shouldn't crash the result screen.
  double minimumScoreForSection(String sectionKey) {
    final scoring = raw['scoring'] as Map<String, dynamic>;
    final configKey = switch (sectionKey) {
      'listening' || 'reading' => 'receptive',
      _ => sectionKey,
    };
    final fieldKey = switch (sectionKey) {
      'listening' || 'reading' => 'minimumPerSkill',
      'writing' || 'speaking' => 'minimumTaskCriterionAverage',
      'mediation' => 'minimumCriterionAverage',
      _ => 'minimumPerSkill',
    };
    final config = scoring[configKey] as Map<String, dynamic>?;
    final value = config?[fieldKey] as num?;
    return value?.toDouble() ?? 0.6;
  }
}
