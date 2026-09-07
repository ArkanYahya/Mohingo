import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/locale_preference_provider.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/theme_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/settings/presentation/settings_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
// `Override` isn't part of flutter_riverpod's public export surface (an
// explicit `show` list omits it) — it's only exported from this path.
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../speech/fake_speech_services.dart';

/// Plays `MohingoApp`'s own role of reacting to locale/theme-mode
/// preference changes — only used by the two tests below that actually
/// exercise that reactivity (locale/theme switching). The other two tests
/// use a plain, non-reactive [MaterialApp] instead: wrapping in this
/// `ConsumerWidget` measurably interferes with the Settings `ListView`'s
/// sliver realizing its lower sections (confirmed by comparing
/// `debugDumpApp()` output with and without this wrapper) — a real but
/// narrow test-harness quirk, not a bug in [SettingsScreen] itself.
class _SettingsHarness extends ConsumerWidget {
  const _SettingsHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    final themeMode = ref.watch(themeModePreferenceProvider);
    final colorSeed = ref.watch(colorSeedPreferenceProvider);
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light(colorSeed),
      darkTheme: AppTheme.dark(colorSeed),
      themeMode: themeMode,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const SettingsScreen(),
    );
  }
}

List<Override> _baseOverrides(SharedPreferences prefs, AppDatabase db) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  appDatabaseProvider.overrideWithValue(db),
  textToSpeechServiceProvider.overrideWithValue(FakeTextToSpeechService()),
  speechCapabilityServiceProvider.overrideWithValue(
    FakeSpeechCapabilityService(
      const DeviceSpeechCapabilities(
        sttAvailableForLocale: false,
        micPermission: SpeechPermissionStatus.notDetermined,
      ),
    ),
  ),
];

/// Settings' content is taller than the default test surface — a tall
/// surface means every section is on-screen without needing to scroll a
/// sliver into view, the same as it would be on a real tall phone screen
/// showing a short settings page.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<(AppDatabase, SharedPreferences)> _setupBacking() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(
          uuid: 'learner-1',
          createdAt: DateTime.utc(2026, 9, 2),
        ),
      );
  return (db, prefs);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('renders every settings section', (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(3)); // 3 colour seeds
    expect(find.byType(Slider), findsNWidgets(2)); // TTS rate + pitch
    expect(
      find.widgetWithText(OutlinedButton, 'Reset progress'),
      findsOneWidget,
    );
  });

  testWidgets('switching interface language via Settings actually changes '
      'the app locale', (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: const _SettingsHarness(),
      ),
    );
    await tester.pumpAndSettle();

    var context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'ar');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'en');
    expect(Directionality.of(context), TextDirection.ltr);
  });

  testWidgets('switching to dark theme via Settings actually changes the '
      'rendered brightness', (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: const _SettingsHarness(),
      ),
    );
    await tester.pumpAndSettle();

    var context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.light);

    // "داكن" ("Dark") — the screen starts in Arabic, the app's default
    // interface language, so the theme-mode segment labels are Arabic too.
    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();

    context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets(
    'resetting progress clears real data and never touches the Learners row',
    (tester) async {
      _useTallViewport(tester);
      final (db, prefs) = await _setupBacking();

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(prefs, db),
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final learnerId = (await db.select(db.learners).get()).single.id;
      await db
          .into(db.unitProgress)
          .insert(
            UnitProgressCompanion.insert(
              uuid: 'seeded-unit-progress',
              learnerId: learnerId,
              unitId: 'A1-U1',
              state: 'inProgress',
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );
      expect(await db.select(db.unitProgress).get(), hasLength(1));

      final resetButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Reset progress',
      );
      await tester.tap(resetButtonFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog appeared with the destructive-action copy.
      expect(find.text('Reset all progress?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();

      expect(await db.select(db.unitProgress).get(), isEmpty);
      expect(
        await db.select(db.learners).get(),
        hasLength(1),
        reason: 'the learner identity itself must survive a progress reset',
      );
      expect(find.text('Progress reset.'), findsOneWidget);
    },
  );

  testWidgets(
    'entering a name and tapping Save persists it and shows confirmation',
    (tester) async {
      _useTallViewport(tester);
      final (db, prefs) = await _setupBacking();

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(prefs, db),
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name saved'), findsOneWidget);

      final row = await db.select(db.learners).getSingle();
      expect(row.name, 'Ali');
    },
  );
}
