/// The current playback state of the on-device TTS engine.
enum TtsPlaybackState { idle, playing, stopped, error }

/// One voice the device's TTS engine can use for a given locale.
class TtsVoice {
  const TtsVoice({required this.name, required this.localeCode});

  final String name;
  final String localeCode;
}

/// flutter_tts's rate scale runs 0.0–1.0 with this value as normal speed;
/// bundled clips map it to a playback rate (see
/// `BundledAudioTextToSpeechService.playbackRateFor`).
const kNormalTtsRate = 0.5;

/// Reads text aloud.
///
/// The app's binding plays the pre-generated clip a level ships for the
/// text (ADR 0008, docs/DATA_MODEL.md's audio manifest) and hands anything
/// without a clip to the OS's on-device text-to-speech engine. Callers only
/// ever depend on this interface, never on `flutter_tts` or `audioplayers`
/// directly (see `speech_providers.dart` and docs/ARCHITECTURE.md's
/// speech-capability strategy).
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

    /// Who is speaking, when the content says: a dialogue speaker label or
    /// `kPartnerSpeaker`. Chooses the voice of a bundled clip; the device
    /// engine ignores it.
    String? speaker,
  });

  Future<void> stop();

  Stream<TtsPlaybackState> get playbackState;
}
