import '../../../../data/local/database.dart';

/// Queues and resolves open-ended answers awaiting a free online
/// grammar-quality pass — see [PendingOnlineRefinements] and
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
abstract interface class PendingRefinementRepository {
  /// Queues one submitted answer. [canDoIds] is stored JSON-encoded;
  /// [localScore] is the already-computed offline content score. [unitId]
  /// is stored so a later resolution can refresh that unit's cached
  /// mastery state without a content-bundle lookup.
  ///
  /// [evidenceSkill] and [wasFallback] mean exactly what they mean on
  /// `ActivityAttemptRepository.recordAttempt` and are carried through
  /// verbatim, so a `speak` activity answered via its typed-answer
  /// accessibility fallback still resolves into an attempt row pairing
  /// `wasFallback: true` with the fallback skill. See docs/DATA_MODEL.md.
  ///
  /// [meaningSignal] is the on-device meaning signal computed at submission
  /// (ADR 0011), or null when none was available. [onlineAllowed] is false
  /// for a row queued only for the installed AI pack's local judgement —
  /// such a row is never sent to the online grammar check.
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
    bool wasFallback = false,
    double? meaningSignal,
    bool onlineAllowed = true,
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

  /// Clears every queued item for [learnerId].
  ///
  /// Not called from production code today: `AppDatabase.
  /// resetProgressForLearner` deletes from `pendingOnlineRefinements`
  /// directly inside its own transaction (a reset must be atomic across
  /// every progress table at once, which a repository call can't join), so
  /// this exists for completeness of the queue's own interface and is
  /// exercised by its repository test.
  Future<void> removeAllForLearner({required int learnerId});
}
