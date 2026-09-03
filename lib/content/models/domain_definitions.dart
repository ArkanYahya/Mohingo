import 'exceptions.dart';

/// The 6 CEFR competencies tracked by the curriculum bundle's
/// `domain.SKILLS` — note this is broader than the original 4-skill
/// framing: speaking is split into interaction vs. production, and
/// mediation is tracked separately. See docs/GLOSSARY.md.
enum Skill {
  listening,
  reading,
  writing,
  spokenInteraction,
  spokenProduction,
  mediation;

  static Skill parse(String value) {
    return Skill.values.firstWhere(
      (s) => s.name == value,
      orElse: () =>
          throw UnsupportedContentSchemaException('Unknown skill: $value'),
    );
  }
}

/// Whether an activity is first-exposure ([encounter]), unscored rehearsal
/// ([practice]), or mastery-evidence-bearing ([mastery]). `practice` never
/// counts as mastery evidence. See docs/GLOSSARY.md.
enum ActivityMode {
  encounter,
  practice,
  mastery;

  static ActivityMode parse(String value) {
    return ActivityMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => throw UnsupportedContentSchemaException(
        'Unknown activity mode: $value',
      ),
    );
  }
}

/// The curriculum bundle's `domain.MASTERY_POLICY` — the rules
/// [MasteryAggregationService] evaluates against. See docs/DATA_MODEL.md.
class MasteryPolicy {
  const MasteryPolicy({
    required this.minimumObjectiveScore,
    required this.minimumEvidencePerRequiredObjective,
    required this.requireProductiveEvidenceWhereDeclared,
    required this.practiceCountsAsMastery,
    required this.allowSpeechFallbackToWriting,
    required this.speechCriteria,
    required this.speechAccuracyWeight,
  });

  factory MasteryPolicy.fromJson(Map<String, dynamic> json) {
    return MasteryPolicy(
      minimumObjectiveScore: (json['minimumObjectiveScore'] as num).toDouble(),
      minimumEvidencePerRequiredObjective:
          json['minimumEvidencePerRequiredObjective'] as int,
      requireProductiveEvidenceWhereDeclared:
          json['requireProductiveEvidenceWhereDeclared'] as bool,
      practiceCountsAsMastery: json['practiceCountsAsMastery'] as bool,
      allowSpeechFallbackToWriting:
          json['allowSpeechFallbackToWriting'] as bool,
      speechCriteria: List<String>.from(json['speechCriteria'] as List),
      speechAccuracyWeight: (json['speechAccuracyWeight'] as num).toDouble(),
    );
  }

  final double minimumObjectiveScore;
  final int minimumEvidencePerRequiredObjective;
  final bool requireProductiveEvidenceWhereDeclared;
  final bool practiceCountsAsMastery;
  final bool allowSpeechFallbackToWriting;
  final List<String> speechCriteria;
  final double speechAccuracyWeight;
}

/// The curriculum bundle's `domain` object: skills/modes/activity-types are
/// modeled as the [Skill]/[ActivityMode] enums and the [Activity] type
/// hierarchy directly; this class carries what's left — the flat Can-Do
/// objective id set (used to validate unresolved references, see
/// docs/content/parsing) and the [masteryPolicy].
class DomainDefinitions {
  const DomainDefinitions({
    required this.canDoIds,
    required this.masteryPolicy,
  });

  factory DomainDefinitions.fromJson(Map<String, dynamic> json) {
    final canDo = Map<String, dynamic>.from(json['CAN_DO'] as Map);
    return DomainDefinitions(
      canDoIds: canDo.values.map((v) => v as String).toSet(),
      masteryPolicy: MasteryPolicy.fromJson(
        json['MASTERY_POLICY'] as Map<String, dynamic>,
      ),
    );
  }

  /// Every valid Can-Do objective id declared by the bundle's `domain.CAN_DO`
  /// map — used to detect unresolved references (a lesson/activity/unit
  /// pointing at a canDo id that doesn't exist).
  final Set<String> canDoIds;
  final MasteryPolicy masteryPolicy;
}
