/// Microphone permission state, deliberately distinguishing "not yet asked"
/// from "denied" from "permanently denied" (iOS/Android both expose a
/// permanent-denial state where re-requesting is pointless and the UI must
/// instead point the learner at OS settings).
enum SpeechPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
}

/// One partial or final speech-recognition result.
class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.transcript,
    required this.isFinal,
  });

  /// Shown to the learner before submission — see docs/ARCHITECTURE.md
  /// ("make temporary transcripts visible... before submission"). Never
  /// persisted at rest; the caller derives only a minimal graded result
  /// from it. See docs/SECURITY.md.
  final String transcript;
  final bool isFinal;
}

/// Transcribes speech via the OS's on-device speech-recognition engine.
///
/// **Never falsely promises availability**: [isAvailableForLocale] must be
/// checked before [recognize] is used for real — availability genuinely
/// varies by device, OS version, and installed language packs. Every
/// `speak` activity must have a typed-answer fallback path that works when
/// this returns false or [permissionStatus] is denied. See
/// docs/ARCHITECTURE.md.
///
/// Audio is never uploaded and never retained — see docs/SECURITY.md. This
/// is the seam a future `CloudSpeechRecognitionService`/
/// `AiSpeakingEvaluationService` swaps into via provider override; on-device
/// recognition here may only assist simple task-completion checks, never
/// presented as real pronunciation/fluency/CEFR scoring.
abstract interface class SpeechRecognitionService {
  Future<bool> isAvailableForLocale(String localeCode);

  /// Never prompts the user — safe to call at any time (e.g. to render
  /// Settings' permission status) without triggering the OS permission
  /// dialog. Use [requestPermission] for that, and only in response to a
  /// deliberate learner action.
  Future<SpeechPermissionStatus> permissionStatus();

  Future<SpeechPermissionStatus> requestPermission();

  /// Streams partial results (if the platform supports them) followed by
  /// one final result, then completes. Throws if called before permission
  /// is granted or the locale is unavailable — callers must check
  /// [permissionStatus]/[isAvailableForLocale] first.
  Stream<SpeechRecognitionResult> recognize({
    required String localeCode,
    Duration? listenFor,
  });

  Future<void> cancel();
}
