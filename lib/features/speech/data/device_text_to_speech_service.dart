import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../domain/text_to_speech_service.dart';

/// Wraps `package:flutter_tts` (Android `TextToSpeech` / iOS
/// `AVSpeechSynthesizer`). API verified directly against the installed
/// flutter_tts 4.2.5 source this session (`getVoices`/`getLanguages` are
/// async *getters*, not methods; `setVoice` takes a `Map<String,String>`).
///
/// **Not verified on a real device** — no Android/iOS device or emulator is
/// available in this dev environment (see docs/TESTING.md). Needs manual
/// verification on a real device before shipping.
class DeviceTextToSpeechService implements TextToSpeechService {
  DeviceTextToSpeechService({FlutterTts? flutterTts})
    : _tts = flutterTts ?? FlutterTts() {
    _tts.setStartHandler(() => _stateController.add(TtsPlaybackState.playing));
    _tts.setCompletionHandler(
      () => _stateController.add(TtsPlaybackState.stopped),
    );
    _tts.setCancelHandler(() => _stateController.add(TtsPlaybackState.stopped));
    _tts.setErrorHandler((_) => _stateController.add(TtsPlaybackState.error));
    // speak() then completes when the utterance finishes (or errors, or is
    // stopped) rather than when it starts — so callers can play a
    // conversation line by line, and a play button stays "playing" for
    // exactly as long as the speech does.
    unawaited(_tts.awaitSpeakCompletion(true));
  }

  /// An upper bound on one utterance, so an engine that never reports
  /// completion can't leave a caller waiting forever: 5s plus ~8 characters
  /// a second, far slower than any real speaking rate.
  static Duration _speakTimeout(String text) =>
      Duration(seconds: 5 + text.length ~/ 8);

  final FlutterTts _tts;
  final _stateController = StreamController<TtsPlaybackState>.broadcast();

  @override
  Stream<TtsPlaybackState> get playbackState => _stateController.stream;

  @override
  Future<List<TtsVoice>> availableVoicesForLocale(String localeCode) async {
    final dynamic raw = await _tts.getVoices;
    if (raw is! List) return const [];
    final languagePrefix = localeCode.toLowerCase().split(RegExp('[-_]')).first;
    return [
      for (final entry in raw)
        if (entry is Map &&
            entry['name'] is String &&
            entry['locale'] is String &&
            (entry['locale'] as String).toLowerCase().startsWith(
              languagePrefix,
            ))
          TtsVoice(
            name: entry['name'] as String,
            localeCode: entry['locale'] as String,
          ),
    ];
  }

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
  }) async {
    await _tts.setLanguage(localeCode);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    if (voiceName != null) {
      await _tts.setVoice({'name': voiceName, 'locale': localeCode});
    }
    await _tts.speak(text).timeout(_speakTimeout(text), onTimeout: () => null);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
