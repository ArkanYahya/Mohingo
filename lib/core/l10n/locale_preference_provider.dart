import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../preferences/shared_preferences_provider.dart';

part 'locale_preference_provider.g.dart';

const _localeKey = 'settings.locale';

/// Interface language choice (Arabic or English), persisted immediately on
/// change — see docs/UX_PRINCIPLES.md and docs/DESIGN_SYSTEM.md's theming
/// rules ("changes apply immediately, no restart").
///
/// Defaults to Arabic: the app's primary audience is self-directed
/// Arabic-speaking adults (see docs/PRODUCT.md), so Arabic is the interface
/// default rather than English, with no onboarding step required to pick it.
@riverpod
class LocalePreference extends _$LocalePreference {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_localeKey);
    return stored == 'en' ? const Locale('en') : const Locale('ar');
  }

  Future<void> set(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}
