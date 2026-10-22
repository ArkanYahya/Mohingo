/// Where the downloadable AI pack stands on this device (ADR 0011's second
/// layer). Phase A ships no pack, so every build reads [notAvailable]; Phase
/// B adds the download and the other three states.
enum AiPackState {
  /// This build has no pack to offer — the row in Settings says so, as the
  /// backup row did before accounts existed.
  notAvailable,

  /// A pack exists for this build and is not on the device.
  notInstalled,

  /// Being downloaded; [AiPackStatus.progress] is the fraction done.
  downloading,

  /// On the device and healthy: the drain asks it before anything else.
  installed,
}

class AiPackStatus {
  const AiPackStatus({
    required this.state,
    this.name,
    this.version,
    this.sizeBytes,
    this.progress,
  });

  const AiPackStatus.notAvailable() : this(state: AiPackState.notAvailable);

  final AiPackState state;

  /// `<name>` and `<version>` of the pack this build offers, when it offers
  /// one; together they are the `pack` recorded on a judged attempt.
  final String? name;
  final String? version;

  /// The download size, shown before the learner chooses to download.
  final int? sizeBytes;

  /// 0..1 while [AiPackState.downloading]; null otherwise.
  final double? progress;
}

/// How Settings reads and drives the pack. Phase A binds the implementation
/// below; Phase B's downloads, verifies, stores and deletes a real pack.
abstract interface class AiPackService {
  Stream<AiPackStatus> get status;
  Future<void> download();
  Future<void> delete();
}

/// A build that offers no pack: the status never changes, and the actions
/// are no-ops the row never offers.
class NoAiPackService implements AiPackService {
  const NoAiPackService();

  @override
  Stream<AiPackStatus> get status =>
      Stream.value(const AiPackStatus.notAvailable());

  @override
  Future<void> download() async {}

  @override
  Future<void> delete() async {}
}
