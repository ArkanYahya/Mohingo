/// Whether the device currently has network connectivity — used only to
/// decide when it's worth *attempting* the optional online grammar-quality
/// refinement (Tier 2). Never gates any learning feature directly: every
/// caller must have a working offline path. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md and
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
abstract interface class ConnectivityService {
  Future<bool> isOnline();

  /// Emits the new online/offline state on every change. A `true` event is
  /// the trigger the drain-queue provider listens for.
  Stream<bool> get onlineChanges;
}
