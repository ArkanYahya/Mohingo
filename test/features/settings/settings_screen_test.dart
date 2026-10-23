import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/locale_preference_provider.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/theme_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/account/providers/account_providers.dart';
import 'package:mohingo/features/app_guide/providers/app_guide_providers.dart';
import 'package:mohingo/features/settings/presentation/settings_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
// `Override` isn't part of flutter_riverpod's public export surface (an
// explicit `show` list omits it) — it's only exported from this path.
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../account/fake_auth_repository.dart';
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
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light(kAppColorSeed),
      darkTheme: AppTheme.dark(kAppColorSeed),
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

  testWidgets('groups settings under Appearance, Listening & speaking, '
      'Your data and Help & information, and labels the slider ends', (
    tester,
  ) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    expect(find.text(l10n.settingsNameEmpty), findsOneWidget);
    for (final overline in [
      l10n.settingsAppearanceOverline,
      l10n.settingsSpeechTitle,
      l10n.settingsDataOverline,
      l10n.settingsHelpOverline,
    ]) {
      expect(find.text(overline.toUpperCase()), findsOneWidget);
    }
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    // One slider: voice speed. Pitch went with the device engine — bundled
    // clips have none to change (ADR 0008).
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text(l10n.settingsSlower), findsOneWidget);
    expect(find.text(l10n.settingsFaster), findsOneWidget);
    expect(find.text(l10n.settingsResetProgressTitle), findsOneWidget);
    // The AI pack row (ADR 0013): offered under Listening & speaking, and
    // honest that this build has none to download.
    expect(find.text(l10n.settingsSmartFeedbackTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsSmartFeedbackBodyUnavailable),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsSmartFeedbackDownload), findsNothing);
  });

  testWidgets('Try it plays a sample in the chosen voice', (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();
    final tts = FakeTextToSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._baseOverrides(prefs, db).skip(3),
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          textToSpeechServiceProvider.overrideWithValue(tts),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    await tester.tap(find.text(l10n.settingsTryVoice));
    await tester.pumpAndSettle();
    expect(tts.spoken, isNotEmpty);
  });

  testWidgets('Allow asks for the microphone when it has not been asked yet', (
    tester,
  ) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();
    final recognition = FakeSpeechRecognitionService(
      initialPermission: SpeechPermissionStatus.notDetermined,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._baseOverrides(prefs, db),
          speechRecognitionServiceProvider.overrideWithValue(recognition),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    expect(find.text(l10n.settingsMicNotYet), findsOneWidget);
    await tester.tap(find.text(l10n.settingsMicAllow));
    await tester.pumpAndSettle();
    expect(recognition.initialPermission, SpeechPermissionStatus.granted);
  });

  testWidgets('offers no colour choice: light, dark and automatic only', (
    tester,
  ) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    for (final seed in AppColorSeed.values) {
      expect(find.text(seed.labelEn), findsNothing);
    }
    expect(find.text(l10n.settingsThemeModeLight), findsOneWidget);
    expect(find.text(l10n.settingsThemeModeDark), findsOneWidget);
    expect(find.text(l10n.settingsThemeModeSystem), findsOneWidget);
  });

  testWidgets('Help & information opens the app guide and About', (
    tester,
  ) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();
    final container = ProviderContainer(overrides: _baseOverrides(prefs, db));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    expect(find.text(l10n.settingsHelpOverline.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.settingsAboutTitle), findsOneWidget);
    expect(container.read(appGuideControllerProvider).active, isFalse);
    await tester.tap(find.text(l10n.settingsGuideTitle));
    await tester.pump();
    expect(container.read(appGuideControllerProvider).active, isTrue);
    expect(container.read(appGuideControllerProvider).step, 0);
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
            theme: AppTheme.light(AppColorSeed.calmTeal),
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

      await tester.tap(find.text('Reset progress'));
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
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name saved'), findsOneWidget);
      // The profile card now shows it.
      expect(find.text('Ali'), findsOneWidget);

      final row = await db.select(db.learners).getSingle();
      expect(row.name, 'Ali');
    },
  );

  testWidgets('signing out returns to the guest and says so, although the '
      'Sign out row itself disappears with the account', (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();
    final auth = FakeAuthRepository(
      signedIn: FakeAuthRepository.userFor('sara@example.com'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._baseOverrides(prefs, db),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('sara@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    // As on a device: the sign-out reaches the session — and the row
    // unmounts — before the sign-out call itself returns.
    final gate = auth.signOutGate = Completer<void>();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing);
    gate.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(auth.currentUser, isNull);
    expect(find.text('Signed out.'), findsOneWidget);
    expect(find.text('Save your progress to an account'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(container.read(accountSessionProvider).value, isA<GuestSession>());
  });
}
