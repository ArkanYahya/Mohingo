import 'speech_recognition_service.dart';

/// A snapshot of what speech interaction is actually possible right now, on
/// this device, for the requested locale.
class DeviceSpeechCapabilities {
  const DeviceSpeechCapabilities({
    required this.sttAvailableForLocale,
    required this.micPermission,
  });

  final bool sttAvailableForLocale;
  final SpeechPermissionStatus micPermission;

  /// True only when recognition can actually be started right now, with no
  /// further permission prompt needed.
  bool get canRecordNow =>
      sttAvailableForLocale && micPermission == SpeechPermissionStatus.granted;

  /// True when a permission prompt is still worth showing (i.e. the learner
  /// hasn't permanently denied it, and the device supports the locale at
  /// all).
  bool get canRequestPermission =>
      sttAvailableForLocale &&
      micPermission != SpeechPermissionStatus.permanentlyDenied &&
      micPermission != SpeechPermissionStatus.granted;
}

/// A single place to answer "can this learner actually speak into the app
/// right now" — combines [SpeechRecognitionService] locale availability
/// with the current microphone permission, without prompting. Used to
/// decide, before a `speak` activity is even shown, whether to offer the
/// microphone at all or go straight to the typed-answer fallback. See
/// docs/ARCHITECTURE.md.
abstract interface class SpeechCapabilityService {
  Future<DeviceSpeechCapabilities> currentCapabilities({
    required String localeCode,
  });
}
