// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every released level's clip manifest, merged (ADR 0008). A level whose
/// manifest is missing or malformed contributes nothing and is logged —
/// the app must never fail to start over audio; its text simply falls back
/// to the device engine.

@ProviderFor(audioClipIndex)
final audioClipIndexProvider = AudioClipIndexProvider._();

/// Every released level's clip manifest, merged (ADR 0008). A level whose
/// manifest is missing or malformed contributes nothing and is logged —
/// the app must never fail to start over audio; its text simply falls back
/// to the device engine.

final class AudioClipIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<AudioClipIndex>,
          AudioClipIndex,
          FutureOr<AudioClipIndex>
        >
    with $FutureModifier<AudioClipIndex>, $FutureProvider<AudioClipIndex> {
  /// Every released level's clip manifest, merged (ADR 0008). A level whose
  /// manifest is missing or malformed contributes nothing and is logged —
  /// the app must never fail to start over audio; its text simply falls back
  /// to the device engine.
  AudioClipIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioClipIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioClipIndexHash();

  @$internal
  @override
  $FutureProviderElement<AudioClipIndex> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AudioClipIndex> create(Ref ref) {
    return audioClipIndex(ref);
  }
}

String _$audioClipIndexHash() => r'b8406df98f2721053248cbf1f57f66975f5700da';

@ProviderFor(clipPlayer)
final clipPlayerProvider = ClipPlayerProvider._();

final class ClipPlayerProvider
    extends $FunctionalProvider<ClipPlayer, ClipPlayer, ClipPlayer>
    with $Provider<ClipPlayer> {
  ClipPlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipPlayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipPlayerHash();

  @$internal
  @override
  $ProviderElement<ClipPlayer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClipPlayer create(Ref ref) {
    return clipPlayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipPlayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipPlayer>(value),
    );
  }
}

String _$clipPlayerHash() => r'7a1666efbfbe8c80535263c79eb2043d2d8e767f';

/// Bundled clips first, the device engine for anything without one. A
/// different engine is added by writing a new implementation and changing
/// only this binding — no caller changes, since every caller only ever
/// depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.

@ProviderFor(textToSpeechService)
final textToSpeechServiceProvider = TextToSpeechServiceProvider._();

/// Bundled clips first, the device engine for anything without one. A
/// different engine is added by writing a new implementation and changing
/// only this binding — no caller changes, since every caller only ever
/// depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.

final class TextToSpeechServiceProvider
    extends
        $FunctionalProvider<
          TextToSpeechService,
          TextToSpeechService,
          TextToSpeechService
        >
    with $Provider<TextToSpeechService> {
  /// Bundled clips first, the device engine for anything without one. A
  /// different engine is added by writing a new implementation and changing
  /// only this binding — no caller changes, since every caller only ever
  /// depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.
  TextToSpeechServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textToSpeechServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textToSpeechServiceHash();

  @$internal
  @override
  $ProviderElement<TextToSpeechService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TextToSpeechService create(Ref ref) {
    return textToSpeechService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextToSpeechService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextToSpeechService>(value),
    );
  }
}

String _$textToSpeechServiceHash() =>
    r'07020dc725ff2e4d5365a78024aa8d059decb9c2';

@ProviderFor(speechRecognitionService)
final speechRecognitionServiceProvider = SpeechRecognitionServiceProvider._();

final class SpeechRecognitionServiceProvider
    extends
        $FunctionalProvider<
          SpeechRecognitionService,
          SpeechRecognitionService,
          SpeechRecognitionService
        >
    with $Provider<SpeechRecognitionService> {
  SpeechRecognitionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechRecognitionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechRecognitionServiceHash();

  @$internal
  @override
  $ProviderElement<SpeechRecognitionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpeechRecognitionService create(Ref ref) {
    return speechRecognitionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechRecognitionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechRecognitionService>(value),
    );
  }
}

String _$speechRecognitionServiceHash() =>
    r'78687b308d41b298ae034d2296b4fb3e75c8b099';

@ProviderFor(speechCapabilityService)
final speechCapabilityServiceProvider = SpeechCapabilityServiceProvider._();

final class SpeechCapabilityServiceProvider
    extends
        $FunctionalProvider<
          SpeechCapabilityService,
          SpeechCapabilityService,
          SpeechCapabilityService
        >
    with $Provider<SpeechCapabilityService> {
  SpeechCapabilityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechCapabilityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechCapabilityServiceHash();

  @$internal
  @override
  $ProviderElement<SpeechCapabilityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpeechCapabilityService create(Ref ref) {
    return speechCapabilityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechCapabilityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechCapabilityService>(value),
    );
  }
}

String _$speechCapabilityServiceHash() =>
    r'36e4c43ae4cd8f25fa51400ab47380a7d7f1fd98';

/// A fresh capability read each time it's watched — used by Settings'
/// speech-status display, which should reflect the latest permission state
/// (e.g. right after the learner grants/denies it elsewhere), not a stale
/// cached snapshot. Hardcoded to English, matching the rest of the app —
/// see [SpeakActivityView]'s `_localeCode`.

@ProviderFor(currentSpeechCapabilities)
final currentSpeechCapabilitiesProvider = CurrentSpeechCapabilitiesProvider._();

/// A fresh capability read each time it's watched — used by Settings'
/// speech-status display, which should reflect the latest permission state
/// (e.g. right after the learner grants/denies it elsewhere), not a stale
/// cached snapshot. Hardcoded to English, matching the rest of the app —
/// see [SpeakActivityView]'s `_localeCode`.

final class CurrentSpeechCapabilitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceSpeechCapabilities>,
          DeviceSpeechCapabilities,
          FutureOr<DeviceSpeechCapabilities>
        >
    with
        $FutureModifier<DeviceSpeechCapabilities>,
        $FutureProvider<DeviceSpeechCapabilities> {
  /// A fresh capability read each time it's watched — used by Settings'
  /// speech-status display, which should reflect the latest permission state
  /// (e.g. right after the learner grants/denies it elsewhere), not a stale
  /// cached snapshot. Hardcoded to English, matching the rest of the app —
  /// see [SpeakActivityView]'s `_localeCode`.
  CurrentSpeechCapabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSpeechCapabilitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSpeechCapabilitiesHash();

  @$internal
  @override
  $FutureProviderElement<DeviceSpeechCapabilities> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeviceSpeechCapabilities> create(Ref ref) {
    return currentSpeechCapabilities(ref);
  }
}

String _$currentSpeechCapabilitiesHash() =>
    r'456c6054397386d5d2a0afb7b095214da8706ba3';
