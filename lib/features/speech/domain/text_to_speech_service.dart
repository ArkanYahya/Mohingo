/// The current playback state of the on-device TTS engine.
enum TtsPlaybackState { idle, playing, stopped, error }

/// One voice the device's TTS engine can use for a given locale.
class TtsVoice {
  const TtsVoice({required this.name, required this.localeCode});

  final String name;
  final String localeCode;
}

/// Reads text aloud via the OS's on-device text-to-speech engine.
///
/// The bundle ships no pre-recorded audio for listening/pronunciation
/// content — every `audioTranscript`/vocabulary/grammar example is read via
/// this interface at runtime. See docs/DATA_MODEL.md.
///
/// This is the seam a future `CloudTextToSpeechService` swaps into via a
/// provider override (see `speech_providers.dart`) — callers only ever
/// depend on this interface, never on `flutter_tts` directly. See
/// docs/ARCHITECTURE.md's speech-capability strategy.
abstract interface class TextToSpeechService {
  /// Voices the device reports for [localeCode] (e.g. `"en"` or `"en-US"`).
  /// May be empty on platforms/OS versions that don't expose voice listing —
  /// callers must treat an empty list as "use the OS default", not an error.
  Future<List<TtsVoice>> availableVoicesForLocale(String localeCode);

  /// Reads [text] aloud. Completes when the utterance has finished — or
  /// failed, or been [stop]ped — not when it starts, so callers can play
  /// several lines in sequence and show a playing state for exactly as
  /// long as the speech lasts.
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
  });

  Future<void> stop();

  Stream<TtsPlaybackState> get playbackState;
}
