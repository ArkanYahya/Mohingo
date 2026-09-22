import 'dart:async';

import '../domain/audio_clip_index.dart';
import '../domain/clip_player.dart';
import '../domain/text_to_speech_service.dart';

/// Plays the bundled clip for a text when there is one, and hands anything
/// else to the device engine. See ADR 0008.
class BundledAudioTextToSpeechService implements TextToSpeechService {
  BundledAudioTextToSpeechService({
    required Future<AudioClipIndex> index,
    required ClipPlayer player,
    required TextToSpeechService fallback,
  }) : _index = index.catchError((Object _) => const AudioClipIndex.empty()),
       // ignore: prefer_initializing_formals
       _player = player,
       // ignore: prefer_initializing_formals
       _fallback = fallback {
    // The audio card auto-reveals its transcript on an engine error, which
    // only the device engine can report — pass its states through.
    _fallback.playbackState.listen(_state.add);
  }

  final Future<AudioClipIndex> _index;
  final ClipPlayer _player;
  final TextToSpeechService _fallback;
  final _state = StreamController<TtsPlaybackState>.broadcast();

  /// The learner's rate (flutter_tts scale, [kNormalTtsRate] = normal) as a
  /// playback rate. Clamped so "Slower" stays intelligible and nothing
  /// turns into a chipmunk.
  static double playbackRateFor(double? rate) =>
      rate == null ? 1.0 : (rate / kNormalTtsRate).clamp(0.6, 1.5).toDouble();

  /// Longer than any clip could be at [playbackRate], so a player that
  /// never reports completion cannot pin a play button forever.
  static Duration playbackTimeout(String text, double playbackRate) => Duration(
    milliseconds: ((5 + text.length / 6) * 1000 / playbackRate).round(),
  );

  @override
  Stream<TtsPlaybackState> get playbackState => _state.stream;

  @override
  Future<List<TtsVoice>> availableVoicesForLocale(String localeCode) =>
      _fallback.availableVoicesForLocale(localeCode);

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
    String? speaker,
  }) async {
    final path = (await _index).assetPathFor(text, speaker: speaker);
    if (path != null) {
      final playbackRate = playbackRateFor(rate);
      _state.add(TtsPlaybackState.playing);
      try {
        await _player.play(
          path,
          playbackRate: playbackRate,
          timeout: playbackTimeout(text, playbackRate),
        );
        return;
      } catch (_) {
        // A clip that will not play is no reason to say nothing.
      } finally {
        _state.add(TtsPlaybackState.stopped);
      }
    }
    await _fallback.speak(
      text,
      localeCode: localeCode,
      rate: rate,
      pitch: pitch,
      voiceName: voiceName,
      speaker: speaker,
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _fallback.stop();
  }
}
