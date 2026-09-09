import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../domain/sound_effects_service.dart';

/// Wraps `package:audioplayers`. A fresh [AudioPlayer] per call is
/// deliberate: these are short, fire-and-forget one-shots (never
/// overlapping in practice — at most one activity is ever submitted at a
/// time), so there's no shared player state worth keeping alive between
/// plays, and no risk of two calls fighting over one player's state.
class AudioplayersSoundEffectsService implements SoundEffectsService {
  @override
  Future<void> play(ActivityFeedbackSound sound) async {
    final fileName = switch (sound) {
      ActivityFeedbackSound.correct => 'sounds/correct.wav',
      ActivityFeedbackSound.incorrect => 'sounds/incorrect.wav',
    };
    final player = AudioPlayer();
    await player.play(AssetSource(fileName));
    unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
  }
}
