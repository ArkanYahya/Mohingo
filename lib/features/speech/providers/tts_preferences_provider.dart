import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/preferences/shared_preferences_provider.dart';
import '../domain/text_to_speech_service.dart';

part 'tts_preferences_provider.g.dart';

const _rateKey = 'settings.tts.rate';
const _pitchKey = 'settings.tts.pitch';

const kDefaultTtsRate = kNormalTtsRate; // flutter_tts's 0.0-1.0 scale
const kDefaultTtsPitch = 1.0; // flutter_tts's ~0.5-2.0 scale; 1.0 = normal

/// Speaking rate, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart"), applied the same way here.
@riverpod
class TtsRatePreference extends _$TtsRatePreference {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble(_rateKey) ?? kDefaultTtsRate;
  }

  Future<void> set(double rate) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_rateKey, rate);
    state = rate;
  }
}

@riverpod
class TtsPitchPreference extends _$TtsPitchPreference {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble(_pitchKey) ?? kDefaultTtsPitch;
  }

  Future<void> set(double pitch) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_pitchKey, pitch);
    state = pitch;
  }
}
