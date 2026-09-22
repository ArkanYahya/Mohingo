/// Plays one bundled clip at a time. The seam that keeps `audioplayers`
/// out of the speech service, so tests can play nothing.
abstract interface class ClipPlayer {
  /// Plays the asset at [assetPath] (a pubspec asset path such as
  /// `assets/audio/en/A1/clips/x.m4a`) at [playbackRate], pitch preserved.
  /// Completes when the clip ends, [stop] is called, or [timeout] passes.
  Future<void> play(
    String assetPath, {
    double playbackRate = 1.0,
    Duration? timeout,
  });

  Future<void> stop();
}
