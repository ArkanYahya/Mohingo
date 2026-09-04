import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` (the ProviderScope.overrides element type) isn't in
// flutter_riverpod's main export list in Riverpod 3 — it lives here.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/app.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/app_shell/presentation/app_shell_scaffold.dart';
import 'package:mohingo/features/review/providers/review_providers.dart';

Future<SharedPreferences> _mockPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Pumps [MohingoApp] and waits for the real A1 curriculum bundle to finish
/// loading before the caller interacts with the shell, so every test below
/// asserts against the real [AppShellScaffold] rather than the splash
/// screen. `pumpAndSettle` alone can never converge here: the splash
/// screen's indeterminate [CircularProgressIndicator] always schedules
/// another frame.
///
/// Both the `pumpWidget` and the wait loop run inside
/// [WidgetTester.runAsync]. The `pumpWidget` placement is load-bearing, not
/// stylistic: `courseContentProvider` parses the bundle off the UI isolate
/// via `Isolate.run`, and that future is created during the *first* build.
/// Started from inside the widget-test fake-async zone it never completes,
/// which left every test after the first one in a file stuck on `/splash`
/// forever (verified: the provider stayed `AsyncLoading` for 30s).
Future<void> _pumpAppAndWaitForContent(
  WidgetTester tester,
  SharedPreferences prefs, {
  List<Override> overrides = const [],
}) async {
  await tester.runAsync(() async {
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
          ...overrides,
        ],
        child: const MohingoApp(),
      ),
    );
    for (var i = 0; i < 100; i++) {
      if (find.byType(AppShellScaffold).evaluate().isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
  });
  await tester.pump();
  // Fail here rather than letting a caller silently assert against the
  // splash screen if the bundle never finished loading.
  expect(find.byType(AppShellScaffold), findsOneWidget);
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

  // These two exercise the real AppShellScaffold rendered by the real
  // router — deliberately not a hand-built NavigationBar replica, which
  // would pass even if production had no badge at all.
  testWidgets('Review nav destination shows a Badge when vocabulary is due', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(
      tester,
      prefs,
      overrides: [
        dueVocabularyCountProvider.overrideWithValue(const AsyncData(3)),
      ],
    );

    final shell = find.byType(AppShellScaffold);
    expect(shell, findsOneWidget);
    final badge = find.descendant(
      of: find.descendant(of: shell, matching: find.byType(NavigationBar)),
      matching: find.byType(Badge),
    );
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('Review nav destination shows no Badge when nothing is due', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(
      tester,
      prefs,
      overrides: [
        dueVocabularyCountProvider.overrideWithValue(const AsyncData(0)),
      ],
    );

    expect(
      find.descendant(
        of: find.byType(AppShellScaffold),
        matching: find.byType(Badge),
      ),
      findsNothing,
    );
  });
}
