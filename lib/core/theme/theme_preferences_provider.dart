import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../preferences/shared_preferences_provider.dart';
import 'color_seed.dart';

part 'theme_preferences_provider.g.dart';

const _themeModeKey = 'settings.themeMode';
const _colorSeedKey = 'settings.colorSeed';

/// Light/dark/system theme choice, persisted immediately on change — see
/// docs/DESIGN_SYSTEM.md's theming rules ("changes apply immediately, no
/// restart").
@riverpod
class ThemeModePreference extends _$ThemeModePreference {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, mode.name);
    state = mode;
  }
}

/// Selected colour-theme seed, persisted immediately on change. See
/// docs/DESIGN_SYSTEM.md.
@riverpod
class ColorSeedPreference extends _$ColorSeedPreference {
  @override
  AppColorSeed build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_colorSeedKey);
    return AppColorSeed.values.firstWhere(
      (seed) => seed.name == stored,
      orElse: () => AppColorSeed.calmTeal,
    );
  }

  Future<void> set(AppColorSeed seed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_colorSeedKey, seed.name);
    state = seed;
  }
}
