import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/app.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';

Future<SharedPreferences> _mockPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Pumps [MohingoApp] and waits for the real A1 curriculum bundle to finish
/// loading (parsed off the UI isolate via `Isolate.run` — a real isolate, so
/// it needs [WidgetTester.runAsync] to progress inside a widget test's
/// fake-async zone) before the caller interacts with the shell.
/// `pumpAndSettle` alone can never converge while the splash screen's
/// indeterminate [CircularProgressIndicator] is on screen, since it always
/// schedules another frame.
Future<void> _pumpAppAndWaitForContent(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  // Widget tests must never touch a real on-disk database: AppDatabase.
  // defaults() opens a real file via path_provider, which isn't mocked in
  // the widget-test environment and hangs. Override with an in-memory
  // instance instead — nothing here asserts on persisted progress.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(
          AppDatabase(NativeDatabase.memory()),
        ),
      ],
      child: const MohingoApp(),
    ),
  );
  await tester.pump();

  await tester.runAsync(() async {
    for (var i = 0; i < 50; i++) {
      if (find.byType(NavigationBar).evaluate().isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
  });
  await tester.pump();
}

void main() {
  // Each test intentionally opens its own short-lived in-memory AppDatabase
  // — Drift's "opened multiple times" warning doesn't apply here (no shared
  // QueryExecutor across instances).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('renders all 5 bottom navigation destinations', (tester) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(tester, prefs);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('defaults to Arabic interface language and renders RTL', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(tester, prefs);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('switching to English interface language renders LTR', (
    tester,
  ) async {
    final prefs = await _mockPrefs({'settings.locale': 'en'});
    await _pumpAppAndWaitForContent(tester, prefs);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'en');
    expect(Directionality.of(context), TextDirection.ltr);
  });
}
