import '../../../../data/local/database.dart';

/// Queues and resolves open-ended answers awaiting a free online
/// grammar-quality pass — see [PendingOnlineRefinements] and
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
abstract interface class PendingRefinementRepository {
  /// Queues one submitted answer. [canDoIds] is stored JSON-encoded;
  /// [localScore] is the already-computed offline content score. [unitId]
  /// is stored so a later resolution can refresh that unit's cached
  /// mastery state without a content-bundle lookup.
  Future<int> enqueue({
    required int learnerId,
    required String activityId,
    required String lessonId,
    required String unitId,
    required List<String> canDoIds,
    required String rawAnswer,
    required String evidenceSkill,
    required String mode,
    required double localScore,
  });

  /// Every queued item across every learner — the drain service resolves
  /// whichever learner's items it can reach; in practice there is only one
  /// local learner in v1.
  Future<List<PendingOnlineRefinement>> allPending();

  /// Bumps [id]'s retry bookkeeping after a failed online attempt — never
  /// removes the row.
  Future<void> recordFailedAttempt({
    required int id,
    required DateTime attemptedAt,
  });

  /// Removes [id] once it's been resolved (recorded as a real attempt),
  /// online or via the bounded fallback.
  Future<void> remove({required int id});

  /// Clears every queued item for [learnerId] — used by
  /// `AppDatabase.resetProgressForLearner`.
  Future<void> removeAllForLearner({required int learnerId});
}
