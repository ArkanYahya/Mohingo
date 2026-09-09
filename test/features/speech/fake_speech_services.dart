import 'dart:async';

import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';

/// A fake [SpeechCapabilityService] with a fixed, test-controlled result —
/// standing in for a real platform channel, which can't be exercised in a
/// `flutter test` environment. See docs/TESTING.md.
class FakeSpeechCapabilityService implements SpeechCapabilityService {
  FakeSpeechCapabilityService(this.result);

  final DeviceSpeechCapabilities result;

  @override
  Future<DeviceSpeechCapabilities> currentCapabilities({
    required String localeCode,
  }) async => result;
}

/// A fake [SpeechRecognitionService] whose [recognize] stream and
/// [requestPermission] result are fully test-controlled.
class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({
    this.available = true,
    this.initialPermission = SpeechPermissionStatus.granted,
    this.permissionAfterRequest = SpeechPermissionStatus.granted,
    List<SpeechRecognitionResult>? results,
  }) : _results = results ?? const [];

  final bool available;
  SpeechPermissionStatus initialPermission;
  final SpeechPermissionStatus permissionAfterRequest;
  final List<SpeechRecognitionResult> _results;

  bool cancelCalled = false;

  @override
  Future<bool> isAvailableForLocale(String localeCode) async => available;

  @override
  Future<SpeechPermissionStatus> permissionStatus() async => initialPermission;

  @override
  Future<SpeechPermissionStatus> requestPermission() async {
    initialPermission = permissionAfterRequest;
    return permissionAfterRequest;
  }

  @override
  Stream<SpeechRecognitionResult> recognize({
    required String localeCode,
    Duration? listenFor,
  }) {
    // Mirrors the real DeviceSpeechRecognitionService: calling cancel()
    // alone never closes this stream — only a final result does (see
    // cancel() below). A widget that relied on the stream completing after
    // calling cancel() would hang exactly as the real "Stop" button bug
    // did, with an empty (or no-final-result) `_results` list.
    final controller = StreamController<SpeechRecognitionResult>();
    scheduleMicrotask(() async {
      for (final result in _results) {
        if (controller.isClosed) return;
        controller.add(result);
        if (result.isFinal) {
          await controller.close();
          return;
        }
      }
    });
    return controller.stream;
  }

  @override
  Future<void> cancel() async {
    cancelCalled = true;
  }
}

class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spoken = [];
  final _playbackStateController =
      StreamController<TtsPlaybackState>.broadcast();

  @override
  Future<List<TtsVoice>> availableVoicesForLocale(String localeCode) async =>
      const [];

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
  }) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  Stream<TtsPlaybackState> get playbackState => _playbackStateController.stream;

  /// Test hook: simulates the on-device TTS engine reporting a playback
  /// state change (e.g. `TtsPlaybackState.error`, to test a silent/broken
  /// engine).
  void emitPlaybackState(TtsPlaybackState state) =>
      _playbackStateController.add(state);
}
