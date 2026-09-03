import 'activity.dart';

/// One line of a lesson's `encounter.dialogue` — a first-exposure scripted
/// conversation shown before practice activities.
class EncounterDialogueLine {
  const EncounterDialogueLine({
    required this.speaker,
    required this.en,
    required this.ar,
  });

  factory EncounterDialogueLine.fromJson(Map<String, dynamic> json) {
    return EncounterDialogueLine(
      speaker: json['speaker'] as String,
      en: json['en'] as String,
      ar: json['ar'] as String,
    );
  }

  final String speaker;
  final String en;
  final String ar;
}

/// A single teaching session within a [Unit] (e.g. `"A1-U1-L1"`, "My Name").
///
/// [raw] carries the full original JSON, including lesson-level fields not
/// yet given a dedicated typed getter (`scenario`, `readingText`,
/// `uiPolicy`, `privacyNote`, `numberScope`, `placeLanguage`,
/// `pedagogyNote`, `reference`) — present on some lessons, not modeled
/// individually in Phase 4 since app logic doesn't act on them yet. See
/// docs/DATA_MODEL.md.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.lessonType,
    required this.canDo,
    required this.grammar,
    required this.lexicon,
    required this.chunks,
    required this.encounterDialogue,
    required this.activities,
    required this.raw,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final encounter = json['encounter'] as Map<String, dynamic>?;
    final dialogue = encounter?['dialogue'] as List?;
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      lessonType: json['lessonType'] as String,
      canDo: List<String>.from(json['canDo'] as List? ?? const []),
      grammar: List<String>.from(json['grammar'] as List? ?? const []),
      lexicon: List<String>.from(json['lexicon'] as List? ?? const []),
      chunks: List<String>.from(json['chunks'] as List? ?? const []),
      encounterDialogue: dialogue == null
          ? const []
          : dialogue
                .map(
                  (l) =>
                      EncounterDialogueLine.fromJson(l as Map<String, dynamic>),
                )
                .toList(),
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      raw: json,
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final String lessonType;
  final List<String> canDo;
  final List<String> grammar;
  final List<String> lexicon;
  final List<String> chunks;
  final List<EncounterDialogueLine> encounterDialogue;
  final List<Activity> activities;
  final Map<String, dynamic> raw;
}

/// A [Unit]'s mastery policy: which Can-Do objectives are required, which
/// skill groups must have evidence coverage, and the unit's own minimum
/// score threshold. See docs/DATA_MODEL.md and
/// [MasteryAggregationService]'s interpretation of [requiredSkillGroups].
class UnitMastery {
  const UnitMastery({
    required this.requiredObjectives,
    required this.requiredSkillGroups,
    required this.minimumObjectiveScore,
    required this.raw,
  });

  factory UnitMastery.fromJson(Map<String, dynamic> json) {
    return UnitMastery(
      requiredObjectives: List<String>.from(json['requiredObjectives'] as List),
      // A1-U0 ("English Essentials") declares no requiredSkillGroups or
      // minimumObjectiveScore at all (verified this session) — treated as
      // "no group-coverage constraint" / "fall back to the domain-level
      // MasteryPolicy.minimumObjectiveScore", not a parse failure.
      requiredSkillGroups:
          (json['requiredSkillGroups'] as List?)
              ?.map((group) => List<String>.from(group as List))
              .toList() ??
          const [],
      minimumObjectiveScore: (json['minimumObjectiveScore'] as num?)
          ?.toDouble(),
      raw: json,
    );
  }

  final List<String> requiredObjectives;

  /// Skill-coverage buckets the unit's required-objective evidence must
  /// collectively touch (e.g. `[["listening"], ["spokenInteraction",
  /// "spokenProduction", "writing"]]`) — not a per-objective requirement
  /// that every objective clears every group. Empty when the unit declares
  /// none (e.g. A1-U0). See [MasteryAggregationService] for the exact
  /// evaluation rule.
  final List<List<String>> requiredSkillGroups;

  /// Null when the unit doesn't declare its own threshold (e.g. A1-U0) —
  /// callers fall back to `MasteryPolicy.minimumObjectiveScore` in that
  /// case. See [MasteryAggregationService].
  final double? minimumObjectiveScore;

  /// Carries `missionRequired`, `retry`, `privacyAlternativeRequired`,
  /// `unlocks` — present in the bundle but not yet acted on by app logic
  /// (flagged in docs/ARCHITECTURE.md as needing a pedagogy sign-off before
  /// they're wired into gating/UI).
  final Map<String, dynamic> raw;
}

/// A top-level curriculum section (e.g. `"A1-U1"`, "Hello, I'm…"). Contains
/// several [Lesson]s. There is no Block entity in the real curriculum data —
/// A1 is 13 flat units. See docs/GLOSSARY.md.
class Unit {
  const Unit({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.levelRole,
    required this.estimatedMinutes,
    required this.countsTowardA1Mastery,
    required this.lessons,
    required this.mastery,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String,
      levelRole: json['levelRole'] as String,
      estimatedMinutes: List<int>.from(json['estimatedMinutes'] as List),
      countsTowardA1Mastery: json['countsTowardA1Mastery'] as bool,
      lessons: (json['lessons'] as List)
          .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      mastery: UnitMastery.fromJson(json['mastery'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String title;
  final String titleAr;
  final String levelRole;

  /// `[min, max]` estimated guided-learning minutes.
  final List<int> estimatedMinutes;
  final bool countsTowardA1Mastery;
  final List<Lesson> lessons;
  final UnitMastery mastery;
}
