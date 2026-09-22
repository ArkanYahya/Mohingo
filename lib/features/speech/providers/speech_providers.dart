import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/providers/course_content_providers.dart';
import '../data/audioplayers_clip_player.dart';
import '../data/bundled_audio_text_to_speech_service.dart';
import '../data/device_speech_capability_service.dart';
import '../data/device_speech_recognition_service.dart';
import '../data/device_text_to_speech_service.dart';
import '../domain/audio_clip_index.dart';
import '../domain/clip_player.dart';
import '../domain/speech_capability_service.dart';
import '../domain/speech_recognition_service.dart';
import '../domain/text_to_speech_service.dart';

part 'speech_providers.g.dart';

/// Every released level's clip manifest, merged (ADR 0008). A level whose
/// manifest is missing or malformed contributes nothing and is logged —
/// the app must never fail to start over audio; its text simply falls back
/// to the device engine.
@Riverpod(keepAlive: true)
Future<AudioClipIndex> audioClipIndex(Ref ref) async {
  final manifests = <AudioManifest>[];
  for (final entry in ref.watch(levelCatalogProvider)) {
    final path = entry.audioManifestAssetPath;
    if (path == null) continue;
    try {
      final json = await rootBundle.loadString(path);
      manifests.add(AudioManifest.parse(json, assetDirectory: p.dirname(path)));
    } catch (e) {
      debugPrint('audio manifest $path unusable: $e');
    }
  }
  return AudioClipIndex.fromManifests(manifests);
}

@Riverpod(keepAlive: true)
ClipPlayer clipPlayer(Ref ref) => AudioplayersClipPlayer();

/// Bundled clips first, the device engine for anything without one. A
/// different engine is added by writing a new implementation and changing
/// only this binding — no caller changes, since every caller only ever
/// depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.
@Riverpod(keepAlive: true)
TextToSpeechService textToSpeechService(Ref ref) {
  return BundledAudioTextToSpeechService(
    index: ref.watch(audioClipIndexProvider.future),
    player: ref.watch(clipPlayerProvider),
    fallback: DeviceTextToSpeechService(),
  );
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
