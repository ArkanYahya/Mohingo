// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Light/dark/system theme choice, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart").

@ProviderFor(ThemeModePreference)
final themeModePreferenceProvider = ThemeModePreferenceProvider._();

/// Light/dark/system theme choice, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart").
final class ThemeModePreferenceProvider
    extends $NotifierProvider<ThemeModePreference, ThemeMode> {
  /// Light/dark/system theme choice, persisted immediately on change — see
  /// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
  /// restart").
  ThemeModePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModePreferenceHash();

  @$internal
  @override
  ThemeModePreference create() => ThemeModePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModePreferenceHash() =>
    r'da31778bb4d17980b6e42cfb0e0175792fd42fb4';

/// Light/dark/system theme choice, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart").

abstract class _$ThemeModePreference extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
