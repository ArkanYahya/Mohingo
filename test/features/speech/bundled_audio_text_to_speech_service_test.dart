import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/speech/data/bundled_audio_text_to_speech_service.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';
import 'package:mohingo/features/speech/domain/clip_player.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';

import 'fake_speech_services.dart';

class FakeClipPlayer implements ClipPlayer {
  final played = <(String, double)>[];
  bool stopped = false;
  bool failNext = false;
  Completer<void>? current;

  @override
  Future<void> play(
    String assetPath, {
    double playbackRate = 1.0,
    Duration? timeout,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('cannot play');
    }
    played.add((assetPath, playbackRate));
    current = Completer<void>();
    await current!.future;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    if (current != null && !current!.isCompleted) current!.complete();
  }
}

void main() {
  const manifest =
      '{"levelId":"a1","contentVersion":"v","clips":{'
      '"5c3e9f7ad0c9c2b8":{"_":"clips/t.m4a","Omar":"clips/o.m4a"}}}';
  final index = AudioClipIndex.fromManifests([
    AudioManifest.parse(manifest, assetDirectory: 'assets/audio/en/A1'),
  ]);

  late FakeClipPlayer player;
  late FakeTextToSpeechService fallback;
  late BundledAudioTextToSpeechService service;

  setUp(() {
    player = FakeClipPlayer();
    fallback = FakeTextToSpeechService();
    service = BundledAudioTextToSpeechService(
      index: Future.value(index),
      player: player,
      fallback: fallback,
    );
  });

  test('plays the clip for the speaker and reports playing then stopped', () async {
    final states = <TtsPlaybackState>[];
    final sub = service.playbackState.listen(states.add);
    final done = service.speak(
      'Good morning.',
      localeCode: 'en',
      speaker: 'Omar',
      rate: 0.5,
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.played, [('assets/audio/en/A1/clips/o.m4a', 1.0)]);
    expect(fallback.spoken, isEmpty);
    player.current!.complete();
    await done;
    await Future<void>.delayed(Duration.zero);
    expect(states, [TtsPlaybackState.playing, TtsPlaybackState.stopped]);
    await sub.cancel();
  });

  test('falls back to the device engine when there is no clip', () async {
    await service.speak(
      'Not bundled.',
      localeCode: 'en',
      rate: 0.5,
      speaker: 'Omar',
    );
    expect(player.played, isEmpty);
    expect(fallback.spoken, ['Not bundled.']);
    expect(fallback.speakers, ['Omar']);
  });

  test('falls back when the player throws', () async {
    player.failNext = true;
    await service.speak('Good morning.', localeCode: 'en');
    expect(fallback.spoken, ['Good morning.']);
  });

  test('maps the flutter_tts rate scale to playback rate', () {
    expect(BundledAudioTextToSpeechService.playbackRateFor(null), 1.0);
    expect(BundledAudioTextToSpeechService.playbackRateFor(0.5), 1.0);
    expect(
      BundledAudioTextToSpeechService.playbackRateFor(0.3),
      closeTo(0.6, 1e-9),
    );
    expect(BundledAudioTextToSpeechService.playbackRateFor(0.25), 0.6);
    expect(BundledAudioTextToSpeechService.playbackRateFor(1.0), 1.5);
  });

  test('the timeout scales with the text and the rate', () {
    final normal = BundledAudioTextToSpeechService.playbackTimeout('x' * 60, 1.0);
    final slow = BundledAudioTextToSpeechService.playbackTimeout('x' * 60, 0.6);
    expect(normal, const Duration(seconds: 15));
    expect(slow, const Duration(seconds: 25));
  });

  test('stop stops the player and the fallback', () async {
    final done = service.speak('Good morning.', localeCode: 'en');
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    await done;
    expect(player.stopped, isTrue);
    expect(fallback.stopCalls, 1);
  });

  test('an index that failed to load means the device engine speaks', () async {
    final broken = BundledAudioTextToSpeechService(
      index: Future.error(StateError('no manifest')),
      player: player,
      fallback: fallback,
    );
    await broken.speak('Good morning.', localeCode: 'en');
    expect(fallback.spoken, ['Good morning.']);
  });

  test('the device engine\'s error state reaches listeners', () async {
    final states = <TtsPlaybackState>[];
    final sub = service.playbackState.listen(states.add);
    fallback.emitPlaybackState(TtsPlaybackState.error);
    await Future<void>.delayed(Duration.zero);
    expect(states, [TtsPlaybackState.error]);
    await sub.cancel();
  });
}
