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
/// `pending_online_refinements` immediately if already online, then again
/// every time [ConnectivityService.onlineChanges] reports the device just
/// came online. Never required for any learning feature to function: if
/// this never fires (a learner who's never online), queued items still
/// resolve via `PendingRefinementDrainService`'s bounded local-only
/// fallback the next time a drain happens to run — this provider is only
/// what makes that happen *sooner* when possible. See
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
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

  Future<void> drainIfOnline() async {
    if (await connectivity.isOnline()) {
      await service.drainOnce();
    }
  }

  drainIfOnline();

  final subscription = connectivity.onlineChanges
      .where((isOnline) => isOnline)
      .listen((_) => drainIfOnline());
  ref.onDispose(subscription.cancel);
});
