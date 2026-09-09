import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
// `Override` isn't part of flutter_riverpod's public export surface (an
// explicit `show` list omits it) — it's only exported from this path.
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../speech/fake_speech_services.dart';

/// Wraps [child] with the localization delegates every activity view needs
/// (they read `AppLocalizations.of(context)!`), under [locale], and a
/// [ProviderScope] with the speech services faked out by default — several
/// activity views (e.g. `AudioChoiceActivity`'s transcript card) render a
/// [ListenButton], which needs `textToSpeechServiceProvider` resolvable, and
/// now auto-plays on mount, which also reads `ttsRatePreferenceProvider`/
/// `ttsPitchPreferenceProvider` — both backed by `sharedPreferencesProvider`,
/// so [sharedPreferences] must be resolvable too. Real device plugins have
/// no platform to respond to in `flutter test`; see docs/TESTING.md.
///
/// Pass [textToSpeechService] instead of putting a `textToSpeechServiceProvider`
/// override in [overrides] directly — a provider can't be overridden twice
/// in one container, and this widget already provides the default one.
Widget wrapForTest(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
  TextToSpeechService? textToSpeechService,
  required SharedPreferences sharedPreferences,
}) {
  return ProviderScope(
    overrides: [
      textToSpeechServiceProvider.overrideWithValue(
        textToSpeechService ?? FakeTextToSpeechService(),
      ),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ...overrides,
    ],
    child: MaterialApp(
      // The real theme, not Flutter's Material default — several activity
      // views read `FeedbackTheme`/other AppTheme extensions for their
      // correct/incorrect colours, which only a plain MaterialApp() theme
      // doesn't register.
      theme: AppTheme.light(AppColorSeed.calmTeal),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

extension PumpActivityView on WidgetTester {
  Future<void> pumpActivityView(
    Widget child, {
    Locale locale = const Locale('en'),
    List<Override> overrides = const [],
    TextToSpeechService? textToSpeechService,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpWidget(
      wrapForTest(
        child,
        locale: locale,
        overrides: overrides,
        textToSpeechService: textToSpeechService,
        sharedPreferences: prefs,
      ),
    );
  }
}
