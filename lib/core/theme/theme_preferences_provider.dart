import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences/shared_preferences_provider.dart';

part 'theme_preferences_provider.g.dart';

const _themeModeKey = 'settings.themeMode';

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

/// Preference keys earlier versions wrote and nothing reads any more.
/// `settings.colorSeed` held the colour-theme choice, retired in 1.0.0: the
/// app has one brand accent (`kAppColorSeed`) and Settings offers only
/// light, dark or automatic.
const retiredPreferenceKeys = ['settings.colorSeed'];

/// Removes [retiredPreferenceKeys], so an upgraded install carries no
/// setting it can no longer see or change. Called once at start-up.
Future<void> removeRetiredPreferences(SharedPreferences prefs) async {
  for (final key in retiredPreferenceKeys) {
    if (prefs.containsKey(key)) await prefs.remove(key);
  }
}
