// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bound to the `Device*` implementations today. A future cloud service is
/// added by writing a new implementation and changing only this binding
/// (e.g. behind a config flag) — no caller changes, since every caller only
/// ever depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.

@ProviderFor(textToSpeechService)
final textToSpeechServiceProvider = TextToSpeechServiceProvider._();

/// Bound to the `Device*` implementations today. A future cloud service is
/// added by writing a new implementation and changing only this binding
/// (e.g. behind a config flag) — no caller changes, since every caller only
/// ever depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.

final class TextToSpeechServiceProvider
    extends
        $FunctionalProvider<
          TextToSpeechService,
          TextToSpeechService,
          TextToSpeechService
        >
    with $Provider<TextToSpeechService> {
  /// Bound to the `Device*` implementations today. A future cloud service is
  /// added by writing a new implementation and changing only this binding
  /// (e.g. behind a config flag) — no caller changes, since every caller only
  /// ever depends on [TextToSpeechService]. See docs/ARCHITECTURE.md.
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
    r'7a73aca30d64b724f8ac9cdcf28785a148eee0a6';

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
