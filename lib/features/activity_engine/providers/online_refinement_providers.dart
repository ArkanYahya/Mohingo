import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../data/local/database_provider.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../data/device_connectivity_service.dart';
import '../data/drift_pending_refinement_repository.dart';
import '../data/language_tool_grammar_check_service.dart';
import '../domain/evaluation/connectivity_service.dart';
import '../domain/evaluation/grammar_check_service.dart';
import '../domain/evaluation/pending_refinement_drain_service.dart';
import '../domain/repositories/pending_refinement_repository.dart';

part 'online_refinement_providers.g.dart';

/// Bound to the real device implementation today, same seam pattern as
/// `speech_providers.dart`'s `textToSpeechServiceProvider` — a future
/// alternative implementation swaps in by changing only this binding.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return DeviceConnectivityService();
}

/// Bound to the real LanguageTool-backed implementation today, same seam
/// pattern as [connectivityService] above — a future alternative
/// implementation swaps in by changing only this binding.
@Riverpod(keepAlive: true)
GrammarCheckService grammarCheckService(Ref ref) {
  return LanguageToolGrammarCheckService();
}

/// The single [PendingRefinementRepository] binding for v1 — same seam
/// pattern as [connectivityService]/[grammarCheckService] above.
@Riverpod(keepAlive: true)
PendingRefinementRepository pendingRefinementRepository(Ref ref) {
  return DriftPendingRefinementRepository(ref.watch(appDatabaseProvider));
}

/// Watched once at app root (`MohingoApp`) — drains
/// `pending_online_refinements` once at startup, then again every time
/// [ConnectivityService.onlineChanges] reports the device just came online.
///
/// The drain runs **unconditionally** at both trigger points — never gated
/// on [ConnectivityService.isOnline]. `PendingRefinementDrainService`'s
/// bounded local-only fallback (the mechanism that guarantees a learner who
/// is never online still gets every queued answer resolved, per
/// [ADR 0005](docs/adr/0005-narrow-network-exception-for-open-ended-grading.md))
/// lives *inside* `drainOnce()`, so gating that call on connectivity would
/// make the fallback unreachable on exactly the devices it exists for.
/// Calling it while offline is safe on its own terms: the grammar check
/// throws [GrammarCheckUnavailableException] with no network, and
/// `PendingRefinementDrainService`'s own per-item handling already turns
/// that into either a retry or — once the row is retried/old enough — a
/// local-score-only resolution. Regained connectivity is still a useful
/// *extra* trigger (it's when an online refinement can actually succeed);
/// it just isn't a precondition for draining at all.
///
/// At most one drain is ever in flight: both triggers are fire-and-forget
/// and one grammar check can take up to 10s, so two overlapping drains
/// would otherwise both read the same queue rows and record the same answer
/// as mastery evidence twice (the loser's `remove(id:)` being a silent
/// no-op).
///
/// [OnItemResolved] is wired here, not inside the drain service itself,
/// because refreshing a unit's cached mastery state needs a real [Unit]
/// from the content bundle plus `MasteryAggregationService` — content and
/// Riverpod concerns the drain service deliberately knows nothing about.
final pendingRefinementDrainerProvider = Provider<void>((ref) {
  final service = PendingRefinementDrainService(
    pendingRepository: ref.watch(pendingRefinementRepositoryProvider),
    attemptRepository: ref.watch(activityAttemptRepositoryProvider),
    grammarCheckService: ref.watch(grammarCheckServiceProvider),
    onItemResolved: ({required learnerId, required unitId}) async {
      final index = await ref.read(courseContentProvider('a1').future);
      final unit = index.unitsById[unitId];
      // The content bundle could in principle change between when an item
      // was queued and when it resolves; nothing to refresh if the unit no
      // longer exists.
      if (unit == null) return;
      await ref
          .read(masteryAggregationServiceProvider)
          .refreshUnitProgress(
            learnerId: learnerId,
            unit: unit,
            masteryPolicy: index.bundle.domain.masteryPolicy,
          );
      ref.invalidate(allUnitProgressProvider);
      ref.invalidate(
        lessonProgressForUnitProvider((learnerId: learnerId, unitId: unitId)),
      );
      ref.invalidate(
        lessonAttemptsForUnitProvider((learnerId: learnerId, unitId: unitId)),
      );
      ref.invalidate(allLessonProgressProvider);
    },
  );
  final connectivity = ref.watch(connectivityServiceProvider);

  // Captured by the closures below (same shape as `subscription`), never a
  // module-level global — one guard per drainer instance is exactly the
  // scope that matters.
  var draining = false;
  Future<void> drain() async {
    // Synchronous check-and-set: nothing awaits between reading and
    // writing `draining`, so a second trigger can never slip past it.
    if (draining) return;
    draining = true;
    try {
      await service.drainOnce();
    } finally {
      draining = false;
    }
  }

  // Nothing awaits either trigger, so an unexpected failure would otherwise
  // become an unhandled async error — swallowed silently in release, a
  // crash in debug. Log it and move on: the queue rows are untouched and
  // the next trigger tries again.
  void startDrain() {
    unawaited(
      drain().catchError((Object error, StackTrace stackTrace) {
        debugPrint(
          'Pending online-refinement drain failed: $error\n$stackTrace',
        );
      }),
    );
  }

  startDrain();

  final subscription = connectivity.onlineChanges
      .where((isOnline) => isOnline)
      .listen((_) => startDrain());
  ref.onDispose(subscription.cancel);
});
