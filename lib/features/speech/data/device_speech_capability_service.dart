// Constructor param intentionally doesn't match the private field name
// (kept readable at call sites, e.g. `recognition:`) — an initializing
// formal would force the underscored field name into the public API.
// ignore_for_file: prefer_initializing_formals

import '../domain/speech_capability_service.dart';
import '../domain/speech_recognition_service.dart';

/// Combines [SpeechRecognitionService.permissionStatus] (never prompts)
/// with a best-effort locale-availability read.
///
/// **Documented limitation**: genuine locale/on-device-recognition
/// availability can only be confirmed by actually calling
/// `speech_to_text.initialize()`, which may itself prompt for permission on
/// first call on some platforms — this service must never do that
/// speculatively (e.g. just to render a capability badge on screen load),
/// per docs/ARCHITECTURE.md's "request permission only on deliberate
/// action" rule. So when permission hasn't been determined yet,
/// [currentCapabilities] optimistically reports `sttAvailableForLocale:
/// true` rather than probing — the real availability check happens lazily,
/// the first time the learner actually taps "record" (see
/// `DeviceSpeechRecognitionService.isAvailableForLocale`). If the device
/// genuinely can't recognise the locale, that first attempt fails cleanly
/// and the UI falls back to typed input — never a permanent
/// mis-declaration, just a one-attempt-late correction. Needs real-device
/// verification (see docs/TESTING.md) to confirm this trade-off feels right
/// in practice.
class DeviceSpeechCapabilityService implements SpeechCapabilityService {
  DeviceSpeechCapabilityService({required SpeechRecognitionService recognition})
    : _recognition = recognition;

  final SpeechRecognitionService _recognition;

  @override
  Future<DeviceSpeechCapabilities> currentCapabilities({
    required String localeCode,
  }) async {
    final permission = await _recognition.permissionStatus();
    final sttAvailable = permission == SpeechPermissionStatus.permanentlyDenied
        ? false
        : (permission == SpeechPermissionStatus.granted
              ? await _recognition.isAvailableForLocale(localeCode)
              : true);

    return DeviceSpeechCapabilities(
      sttAvailableForLocale: sttAvailable,
      micPermission: permission,
    );
  }
}
