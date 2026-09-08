// Constructor params intentionally don't match the private field names 1:1
// (kept readable at call sites, e.g. `attemptRepository:`) — initializing
// formals would force the underscored field name into the public API.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../../../../content/models/domain_definitions.dart';
import '../../../../data/local/database.dart';
import '../../../progress/domain/repositories/activity_attempt_repository.dart';
import '../repositories/pending_refinement_repository.dart';
import 'grammar_check_service.dart';

/// Called after a queue row is actually finalized (recorded as a real
/// attempt and removed) — never for a mere failed-attempt retry. Lets the
/// caller refresh whatever depends on that unit's mastery state without
/// this service knowing anything about Riverpod or content lookups. See
/// Task 10.
typedef OnItemResolved = Future<void> Function({
  required int learnerId,
  required String unitId,
});

/// Resolves queued open-ended answers: a real online grammar-quality pass
/// when it succeeds, or — once a row has failed enough times or sat long
/// enough — its already-stored local content score alone. Either way, this
/// is the only place a `pending_online_refinements` row turns into a real
/// `ActivityAttempts` row. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md's Tier 2 and
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
class PendingRefinementDrainService {
  PendingRefinementDrainService({
    required PendingRefinementRepository pendingRepository,
    required ActivityAttemptRepository attemptRepository,
    required GrammarCheckService grammarCheckService,
    this.onItemResolved,
    this.maxAttemptsBeforeFallback = 5,
    this.maxAgeBeforeFallback = const Duration(days: 14),
  }) : _pendingRepository = pendingRepository,
       _attemptRepository = attemptRepository,
       _grammarCheckService = grammarCheckService;

  final PendingRefinementRepository _pendingRepository;
  final ActivityAttemptRepository _attemptRepository;
  final GrammarCheckService _grammarCheckService;

  /// Invoked once per finalized item — see [OnItemResolved]. `null` (the
  /// default) is a legitimate choice for a caller that doesn't need it
  /// (e.g. a script or test with no provider tree to refresh).
  final OnItemResolved? onItemResolved;

  /// A queue row this many failed attempts old finalizes via its local
  /// score alone, rather than waiting on the network indefinitely.
  final int maxAttemptsBeforeFallback;

  /// A queue row this old finalizes via its local score alone even on its
  /// first failed attempt — the age bound, independent of retry count.
  final Duration maxAgeBeforeFallback;

  /// Resolves up to [maxItems] queued rows. Safe to call opportunistically
  /// and often — an empty queue is a no-op, and every row either resolves
  /// or is left untouched for the next call. Safe to call while offline
  /// too: each item's own failure handling (below) turns "no network" into
  /// a retry or, once bounded, a local-score-only resolution, which is what
  /// makes the never-online learner's guarantee actually reachable.
  Future<void> drainOnce({int maxItems = 5}) async {
    final pending = await _pendingRepository.allPending();
    for (final item in pending.take(maxItems)) {
      try {
        await _resolveOne(item);
      } catch (error) {
        // Per-item isolation. `_finalize` parses stored strings
        // (`ActivityMode.parse`, `Skill.parse`, `jsonDecode`), any of which
        // can throw on unexpected/corrupted data. Rows are processed in
        // `allPending()` order, so without this one poison row would abort
        // the whole batch and re-throw identically on every future call —
        // permanently wedging every row behind it. Treat it as a failed
        // attempt for *that* item only (exactly like a grammar-check
        // failure) and keep going.
        await _recordFailedAttemptQuietly(item);
      }
    }
  }

  /// Bumps [item]'s retry bookkeeping, tolerating the row already being
  /// gone — an item that threw *after* `_finalize` removed it has nothing
  /// left to retry, and the rest of the batch must still run.
  Future<void> _recordFailedAttemptQuietly(PendingOnlineRefinement item) async {
    try {
      await _pendingRepository.recordFailedAttempt(
        id: item.id,
        attemptedAt: DateTime.now(),
      );
    } catch (_) {
      // Nothing further to do — deliberately swallowed.
    }
  }

  Future<void> _resolveOne(PendingOnlineRefinement item) async {
    GrammarCheckResult? grammarResult;
    try {
      grammarResult = await _grammarCheckService.check(
        _plainAnswerText(item.rawAnswer),
        localeCode: 'en',
      );
    } on GrammarCheckUnavailableException {
      grammarResult = null;
    }

    if (grammarResult == null) {
      final age = DateTime.now().difference(item.submittedAt);
      final wouldExceedAttempts =
          item.attemptCount + 1 >= maxAttemptsBeforeFallback;
      if (wouldExceedAttempts || age >= maxAgeBeforeFallback) {
        await _finalize(item, score: item.localScore);
      } else {
        await _pendingRepository.recordFailedAttempt(
          id: item.id,
          attemptedAt: DateTime.now(),
        );
      }
      return;
    }

    await _finalize(
      item,
      score: _combineScores(item.localScore, grammarResult),
    );
  }

  /// The learner's actual sentence, decoded out of the JSON-encoded form
  /// `rawAnswer` is stored in (`jsonEncode(text)`, matching
  /// `activity_attempts.raw_answer` everywhere else in this app).
  ///
  /// Only the *grammar check* needs the plain text — sending it the JSON
  /// literal would hand LanguageTool the enclosing quote marks and literal
  /// two-character `\n` escapes, inflating the error density and corrupting
  /// the word count. What gets written back to `activity_attempts` stays
  /// JSON-encoded, unchanged. A value that isn't a JSON string (older or
  /// hand-written queue data) is used as-is rather than failing the item.
  String _plainAnswerText(String rawAnswer) {
    try {
      final decoded = jsonDecode(rawAnswer);
      if (decoded is String) return decoded;
    } on FormatException {
      // Not JSON at all — fall through to the raw value.
    }
    return rawAnswer;
  }

  /// Content coverage (the offline score) still dominates: grammar quality
  /// can subtract at most 30% of the final score, and only in proportion to
  /// how error-dense the answer actually is. A learner who covers every
  /// required point with a few typos should still pass; grammar alone can
  /// never turn a fully-covered answer into a failing one.
  double _combineScores(double localScore, GrammarCheckResult grammar) {
    final words = grammar.wordCount == 0 ? 1 : grammar.wordCount;
    final errorDensity = grammar.errorCount / words;
    final grammarScore = (1.0 - errorDensity * 4).clamp(0.0, 1.0);
    return (localScore * 0.7) + (grammarScore * 0.3);
  }

  Future<void> _finalize(
    PendingOnlineRefinement item, {
    required double score,
  }) async {
    await _attemptRepository.recordAttempt(
      learnerId: item.learnerId,
      activityId: item.activityId,
      lessonId: item.lessonId,
      sessionType: 'lesson',
      mode: ActivityMode.parse(item.mode),
      evidenceSkill: Skill.parse(item.evidenceSkill),
      canDoIds: (jsonDecode(item.canDoIds) as List).cast<String>(),
      rawAnswer: item.rawAnswer,
      isCorrect: score >= 0.75,
      score: score,
      wasFallback: item.wasFallback,
    );
    await _pendingRepository.remove(id: item.id);
    await onItemResolved?.call(learnerId: item.learnerId, unitId: item.unitId);
  }
}
