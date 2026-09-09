// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_effects_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bound to the real `audioplayers`-backed implementation today, same seam
/// pattern as `speech_providers.dart`'s `textToSpeechServiceProvider`.

@ProviderFor(soundEffectsService)
final soundEffectsServiceProvider = SoundEffectsServiceProvider._();

/// Bound to the real `audioplayers`-backed implementation today, same seam
/// pattern as `speech_providers.dart`'s `textToSpeechServiceProvider`.

final class SoundEffectsServiceProvider
    extends
        $FunctionalProvider<
          SoundEffectsService,
          SoundEffectsService,
          SoundEffectsService
        >
    with $Provider<SoundEffectsService> {
  /// Bound to the real `audioplayers`-backed implementation today, same seam
  /// pattern as `speech_providers.dart`'s `textToSpeechServiceProvider`.
  SoundEffectsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundEffectsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soundEffectsServiceHash();

  @$internal
  @override
  $ProviderElement<SoundEffectsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SoundEffectsService create(Ref ref) {
    return soundEffectsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoundEffectsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoundEffectsService>(value),
    );
  }
}

String _$soundEffectsServiceHash() =>
    r'ec3893800b6e5f9e32380e249e3d204c5240dd90';
