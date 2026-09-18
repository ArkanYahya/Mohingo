import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mohingo/features/speech/data/device_text_to_speech_service.dart';

/// Stands in for the platform plugin: records the completion mode and lets
/// each test decide when (or whether) an utterance finishes.
class _FakeFlutterTts extends FlutterTts {
  bool? awaitCompletion;
  final List<String> spoken = [];
  Completer<void> utterance = Completer<void>();

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async {
    this.awaitCompletion = awaitCompletion;
  }

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) {
    spoken.add(text);
    return utterance.future;
  }

  @override
  Future<dynamic> stop() async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asks the engine to report completion, so speak() finishes when the '
      'utterance does — callers can play lines one after another', () async {
    final tts = _FakeFlutterTts();
    final service = DeviceTextToSpeechService(flutterTts: tts);
    await Future<void>.delayed(Duration.zero);

    expect(tts.awaitCompletion, isTrue);

    var done = false;
    final speaking = service
        .speak('Hi.', localeCode: 'en')
        .then((_) => done = true);
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse, reason: 'still speaking');

    tts.utterance.complete();
    await speaking;
    expect(done, isTrue);
  });

  testWidgets('never hangs on an engine that stops reporting: speak() gives '
      'up after a length-based timeout', (tester) async {
    final tts = _FakeFlutterTts();
    final service = DeviceTextToSpeechService(flutterTts: tts);
    var done = false;
    unawaited(service.speak('Hi.', localeCode: 'en').then((_) => done = true));

    await tester.pump(const Duration(seconds: 4));
    expect(done, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(done, isTrue);
  });
}
