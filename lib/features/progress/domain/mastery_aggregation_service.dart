// Constructor params intentionally don't match the private field names 1:1
// (kept readable at call sites, e.g. `attemptRepository:`) — initializing
// formals would force the underscored field name into the public API.
// ignore_for_file: prefer_initializing_formals

import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../data/local/database.dart';
import 'repositories/activity_attempt_repository.dart';
import 'repositories/unit_lesson_progress_repository.dart';

/// The result of evaluating one [Unit]'s mastery for one learner.
class UnitMasteryResult {
  const UnitMasteryResult({
    required this.unitId,
    required this.isMastered,
    required this.masteredObjectiveIds,
    required this.unmasteredObjectiveIds,
    required this.missingSkillGroups,
    required this.hasAnyEvidence,
  });

  final String unitId;
  final bool isMastered;
  final Set<String> masteredObjectiveIds;
  final Set<String> unmasteredObjectiveIds;

  /// Skill groups (from [UnitMastery.requiredSkillGroups]) with no covering
  /// evidence yet — empty when [isMastered] is true.
  final List<List<String>> missingSkillGroups;

  /// Whether any mastery-mode evidence exists for this unit at all — used to
  /// distinguish `notStarted` from `inProgress`.
  final bool hasAnyEvidence;
}

/// Computes Can-Do-objective mastery from recorded evidence and refreshes
/// the [UnitLessonProgressRepository] read-model cache.
///
/// This is the one place unit.mastery.requiredSkillGroups is interpreted —
/// deliberately isolated here rather than duplicated across UI code, since
/// the interpretation is genuinely non-obvious from the bundle data alone
/// (see docs/DATA_MODEL.md and the note below).
///
/// **Interpretation of `requiredSkillGroups`** (e.g. unit A1-U1's
/// `[["listening"], ["spokenInteraction","spokenProduction","writing"]]`):
/// these are unit-level skill-coverage *buckets*, not a requirement that
/// every individual objective clears every group (objectives are already
/// individually tagged to a specific natural skill in the bundle — an
/// objective's evidence is never split across groups). A unit is mastered
/// when (a) **every** required objective individually clears
/// `minimumEvidencePerRequiredObjective` attempts each scoring at least the
/// unit's `minimumObjectiveScore`, **and** (b) the qualifying evidence,
/// taken together, covers **every** declared skill group at least once. This
/// directly implements "a learner who can recognise language but cannot
/// produce it must not be marked fully mastered" — if every required
/// objective happens to be receptive, group (b) still requires productive
/// evidence to exist before the unit can be mastered.
///
/// `practiceCountsAsMastery` and the speaking-fallback-never-counts-as-
/// speaking-evidence rule are both enforced upstream, at write time, by
/// [ActivityAttemptRepository] — `masteryEvidenceForObjective` only ever
/// returns `mode='mastery'` rows with the already-corrected `evidenceSkill`.
class MasteryAggregationService {
  MasteryAggregationService({
    required ActivityAttemptRepository attemptRepository,
    required UnitLessonProgressRepository progressRepository,
  }) : _attemptRepository = attemptRepository,
       _progressRepository = progressRepository;

  final ActivityAttemptRepository _attemptRepository;
  final UnitLessonProgressRepository _progressRepository;

  Future<UnitMasteryResult> evaluateUnit({
    required int learnerId,
    required Unit unit,
    required MasteryPolicy masteryPolicy,
  }) async {
    final masteredObjectives = <String>{};
    final unmasteredObjectives = <String>{};
    final coveredSkills = <String>{};
    var hasAnyEvidence = false;

    final minimumObjectiveScore =
        unit.mastery.minimumObjectiveScore ??
        masteryPolicy.minimumObjectiveScore;

    for (final canDoId in unit.mastery.requiredObjectives) {
      final evidence = await _attemptRepository.masteryEvidenceForObjective(
        learnerId: learnerId,
        canDoId: canDoId,
      );
      if (evidence.isNotEmpty) hasAnyEvidence = true;

      final qualifying = evidence
          .where((a) => _scoreOf(a) >= minimumObjectiveScore)
          .toList();

      if (qualifying.length >=
          masteryPolicy.minimumEvidencePerRequiredObjective) {
        masteredObjectives.add(canDoId);
        for (final attempt in qualifying) {
          coveredSkills.add(attempt.evidenceSkill);
        }
      } else {
        unmasteredObjectives.add(canDoId);
      }
    }

    final missingSkillGroups = <List<String>>[
      for (final group in unit.mastery.requiredSkillGroups)
        if (!group.any(coveredSkills.contains)) group,
    ];

    return UnitMasteryResult(
      unitId: unit.id,
      isMastered: unmasteredObjectives.isEmpty && missingSkillGroups.isEmpty,
      masteredObjectiveIds: masteredObjectives,
      unmasteredObjectiveIds: unmasteredObjectives,
      missingSkillGroups: missingSkillGroups,
      hasAnyEvidence: hasAnyEvidence,
    );
  }

  /// Evaluates [unit] and persists the result to the `unit_progress`
  /// read-model cache. Call after every mastery-mode attempt is recorded.
  /// Preserves the unit's original `masteredAt` timestamp across repeated
  /// calls once mastered — it is never bumped forward on a later refresh.
  Future<UnitMasteryResult> refreshUnitProgress({
    required int learnerId,
    required Unit unit,
    required MasteryPolicy masteryPolicy,
  }) async {
    final result = await evaluateUnit(
      learnerId: learnerId,
      unit: unit,
      masteryPolicy: masteryPolicy,
    );

    final existing = await _progressRepository.unitProgress(
      learnerId: learnerId,
      unitId: unit.id,
    );

    final state = result.isMastered
        ? UnitProgressState.mastered
        : (result.hasAnyEvidence
              ? UnitProgressState.inProgress
              : UnitProgressState.notStarted);

    final masteredAt = result.isMastered
        ? (existing?.masteredAt ?? DateTime.now())
        : null;

    await _progressRepository.upsertUnitProgress(
      learnerId: learnerId,
      unitId: unit.id,
      state: state,
      masteredAt: masteredAt,
    );

    return result;
  }

  double _scoreOf(ActivityAttempt attempt) {
    if (attempt.score != null) return attempt.score!;
    if (attempt.isCorrect != null) return attempt.isCorrect! ? 1.0 : 0.0;
    return 0.0;
  }
}
