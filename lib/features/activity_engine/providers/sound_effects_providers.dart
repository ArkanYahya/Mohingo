import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/audioplayers_sound_effects_service.dart';
import '../domain/sound_effects_service.dart';

part 'sound_effects_providers.g.dart';

/// Bound to the real `audioplayers`-backed implementation today, same seam
/// pattern as `speech_providers.dart`'s `textToSpeechServiceProvider`.
@Riverpod(keepAlive: true)
SoundEffectsService soundEffectsService(Ref ref) {
  return AudioplayersSoundEffectsService();
}
