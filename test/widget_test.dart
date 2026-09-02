import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/app.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';

Future<SharedPreferences> _mockPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('renders all 5 bottom navigation destinations', (tester) async {
    final prefs = await _mockPrefs();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MohingoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('defaults to Arabic interface language and renders RTL', (
    tester,
  ) async {
    final prefs = await _mockPrefs();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MohingoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('switching to English interface language renders LTR', (
    tester,
  ) async {
    final prefs = await _mockPrefs({'settings.locale': 'en'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MohingoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'en');
    expect(Directionality.of(context), TextDirection.ltr);
  });
}
