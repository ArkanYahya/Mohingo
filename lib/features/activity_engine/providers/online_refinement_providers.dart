import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/database_provider.dart';
import '../data/device_connectivity_service.dart';
import '../data/drift_pending_refinement_repository.dart';
import '../data/language_tool_grammar_check_service.dart';
import '../domain/evaluation/connectivity_service.dart';
import '../domain/evaluation/grammar_check_service.dart';
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
