// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Interface language choice (Arabic or English), persisted immediately on
/// change — see docs/UX_PRINCIPLES.md and docs/DESIGN_SYSTEM.md's theming
/// rules ("changes apply immediately, no restart").
///
/// Defaults to Arabic: the app's primary audience is self-directed
/// Arabic-speaking adults (see docs/PRODUCT.md), so Arabic is the interface
/// default rather than English, with no onboarding step required to pick it.

@ProviderFor(LocalePreference)
final localePreferenceProvider = LocalePreferenceProvider._();

/// Interface language choice (Arabic or English), persisted immediately on
/// change — see docs/UX_PRINCIPLES.md and docs/DESIGN_SYSTEM.md's theming
/// rules ("changes apply immediately, no restart").
///
/// Defaults to Arabic: the app's primary audience is self-directed
/// Arabic-speaking adults (see docs/PRODUCT.md), so Arabic is the interface
/// default rather than English, with no onboarding step required to pick it.
final class LocalePreferenceProvider
    extends $NotifierProvider<LocalePreference, Locale> {
  /// Interface language choice (Arabic or English), persisted immediately on
  /// change — see docs/UX_PRINCIPLES.md and docs/DESIGN_SYSTEM.md's theming
  /// rules ("changes apply immediately, no restart").
  ///
  /// Defaults to Arabic: the app's primary audience is self-directed
  /// Arabic-speaking adults (see docs/PRODUCT.md), so Arabic is the interface
  /// default rather than English, with no onboarding step required to pick it.
  LocalePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localePreferenceHash();

  @$internal
  @override
  LocalePreference create() => LocalePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localePreferenceHash() => r'460d54d19d1d8aadf3dc2132ea4bafa715a75e58';

/// Interface language choice (Arabic or English), persisted immediately on
/// change — see docs/UX_PRINCIPLES.md and docs/DESIGN_SYSTEM.md's theming
/// rules ("changes apply immediately, no restart").
///
/// Defaults to Arabic: the app's primary audience is self-directed
/// Arabic-speaking adults (see docs/PRODUCT.md), so Arabic is the interface
/// default rather than English, with no onboarding step required to pick it.

abstract class _$LocalePreference extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
