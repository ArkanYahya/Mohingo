import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ai_pack_status.dart';

part 'ai_pack_providers.g.dart';

/// The one binding for the AI pack (ADR 0013). Phase A offers none; Phase B
/// swaps this for the implementation that downloads and manages a real
/// pack, and binds `localJudgementServiceProvider` to it.
@Riverpod(keepAlive: true)
AiPackService aiPackService(Ref ref) {
  return const NoAiPackService();
}

/// What Settings shows: the pack's state on this device.
@riverpod
Stream<AiPackStatus> aiPackStatus(Ref ref) {
  return ref.watch(aiPackServiceProvider).status;
}
