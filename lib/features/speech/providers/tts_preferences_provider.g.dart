// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tts_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Speaking rate, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart"), applied the same way here.

@ProviderFor(TtsRatePreference)
final ttsRatePreferenceProvider = TtsRatePreferenceProvider._();

/// Speaking rate, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart"), applied the same way here.
final class TtsRatePreferenceProvider
    extends $NotifierProvider<TtsRatePreference, double> {
  /// Speaking rate, persisted immediately on change — see
  /// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
  /// restart"), applied the same way here.
  TtsRatePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ttsRatePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ttsRatePreferenceHash();

  @$internal
  @override
  TtsRatePreference create() => TtsRatePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$ttsRatePreferenceHash() => r'3a51de02a4228181087168505d35be917f6bfd14';

/// Speaking rate, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart"), applied the same way here.

abstract class _$TtsRatePreference extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TtsPitchPreference)
final ttsPitchPreferenceProvider = TtsPitchPreferenceProvider._();

final class TtsPitchPreferenceProvider
    extends $NotifierProvider<TtsPitchPreference, double> {
  TtsPitchPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ttsPitchPreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ttsPitchPreferenceHash();

  @$internal
  @override
  TtsPitchPreference create() => TtsPitchPreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$ttsPitchPreferenceHash() =>
    r'35d368047e433c90784bb8c04617163277cb9087';

abstract class _$TtsPitchPreference extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
