import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../domain/clip_player.dart';

/// One shared [AudioPlayer]: a speak request always replaces the previous
/// clip, which is exactly the "newer request wins" rule the widgets keep.
///
/// **Not verified on a real device** — no Android/iOS device or emulator is
/// available in this dev environment (see README's known limitations).
class AudioplayersClipPlayer implements ClipPlayer {
  AudioplayersClipPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _player;
  Completer<void>? _done;

  /// `AssetSource` already prefixes `assets/`.
  static String assetName(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

  @override
  Future<void> play(
    String assetPath, {
    double playbackRate = 1.0,
    Duration? timeout,
  }) async {
    await stop();
    final done = _done = Completer<void>();
    final sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _player.setPlaybackRate(playbackRate);
      await _player.play(AssetSource(assetName(assetPath)));
      await done.future.timeout(
        timeout ?? const Duration(minutes: 3),
        onTimeout: () {},
      );
    } finally {
      await sub.cancel();
      if (identical(_done, done)) _done = null;
    }
  }

  @override
  Future<void> stop() async {
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
    await _player.stop();
  }
}
