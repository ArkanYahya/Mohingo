import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/device_speech_capability_service.dart';
import '../data/device_speech_recognition_service.dart';
import '../data/device_text_to_speech_service.dart';
import '../domain/speech_capability_service.dart';
import '../domain/speech_recognition_service.dart';
import '../domain/text_to_speech_service.dart';

part 'speech_providers.g.dart';

/// Bound to the `Device*` implementations today. A future cloud service is
/// added by writing a new implementation and changing only this binding
/// (e.g. behind a config flag) — no caller changes, since every caller only
/// ever depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.
@Riverpod(keepAlive: true)
TextToSpeechService textToSpeechService(Ref ref) {
  return DeviceTextToSpeechService();
}

@Riverpod(keepAlive: true)
SpeechRecognitionService speechRecognitionService(Ref ref) {
  return DeviceSpeechRecognitionService();
}

@Riverpod(keepAlive: true)
SpeechCapabilityService speechCapabilityService(Ref ref) {
  return DeviceSpeechCapabilityService(
    recognition: ref.watch(speechRecognitionServiceProvider),
  );
}

/// A fresh capability read each time it's watched — used by Settings'
/// speech-status display, which should reflect the latest permission state
/// (e.g. right after the learner grants/denies it elsewhere), not a stale
/// cached snapshot. Hardcoded to English, matching the rest of the app —
/// see [SpeakActivityView]'s `_localeCode`.
@riverpod
Future<DeviceSpeechCapabilities> currentSpeechCapabilities(Ref ref) {
  return ref
      .watch(speechCapabilityServiceProvider)
      .currentCapabilities(localeCode: 'en');
}
