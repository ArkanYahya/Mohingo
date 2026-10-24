/// Where the downloadable grammar model stands on this device — ADR 0014's
/// deferred fifth decision, which took over this seam from ADR 0013's
/// language-model pack (tried on a phone, not chosen). No build offers it
/// yet, so every build reads [notAvailable]; the download and the other
/// three states come with the model.
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

/// How Settings reads and drives the download. Today's binding is the
/// implementation below; the grammar model's downloads, verifies, stores and
/// deletes a real file.
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
