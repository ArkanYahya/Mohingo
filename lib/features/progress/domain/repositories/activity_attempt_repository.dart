import '../../../../content/models/domain_definitions.dart';
import '../../../../data/local/database.dart';

/// Records and queries [ActivityAttempt] rows — the app's evidence-of-record
/// for every exercise a learner completes, across ordinary lessons,
/// practice-review sessions, the placement test, the Final Mission, and the
/// Final Assessment (distinguished by `sessionType`).
///
/// [recordAttempt] is **insert-only**: a replayed activity always appends a
/// new row, never overwrites a prior one, so revisiting a completed unit
/// never corrupts mastery history. Only one implementation exists in v1
/// ([DriftActivityAttemptRepository]); the interface is written so a future
/// sync implementation can be swapped in via provider override without
/// touching callers. See docs/DATA_MODEL.md and docs/ARCHITECTURE.md.
abstract interface class ActivityAttemptRepository {
  /// Records one attempt and links it to every Can-Do objective in
  /// [canDoIds] it provides evidence for.
  ///
  /// [evidenceSkill] is the skill this attempt actually counts as evidence
  /// for — normally [Activity.skill], but set to the fallback skill (e.g.
  /// `Skill.writing`) with [wasFallback] `true` when a `speak` activity was
  /// answered via its typed-answer accessibility fallback. This must be
  /// decided by the caller *before* calling this method — recording the
  /// fallback rule at write time is what keeps a speaking fallback from
  /// ever counting as speaking evidence. See docs/DATA_MODEL.md.
  Future<int> recordAttempt({
    required int learnerId,
    required String activityId,
    String? lessonId,
    required String sessionType,
    String? sessionId,
    required ActivityMode mode,
    required Skill evidenceSkill,
    required List<String> canDoIds,
    String? rawAnswer,
    bool? isCorrect,
    double? score,
    String? criteriaScores,
    bool wasFallback = false,
  });

  /// Mastery-mode evidence for one learner + Can-Do objective, restricted to
  /// ordinary lesson training (`sessionType='lesson'`) — never
  /// placement/mission/assessment evidence, which stays isolated from
  /// ordinary mastery tracking. Practice-mode attempts are never returned:
  /// `practiceCountsAsMastery` is always false. See docs/DATA_MODEL.md.
  Future<List<ActivityAttempt>> masteryEvidenceForObjective({
    required int learnerId,
    required String canDoId,
  });

  /// All attempts for one learner within a unit's lessons, for any
  /// `sessionType`/`mode` — used by [MasteryAggregationService] to derive
  /// `notStarted` vs `inProgress` state, and by Review's incorrect-answer
  /// history.
  Future<List<ActivityAttempt>> attemptsForLessons({
    required int learnerId,
    required List<String> lessonIds,
  });
}
