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
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/theme_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/app_guide/presentation/app_guide_overlay.dart';
import 'package:mohingo/features/app_guide/providers/app_guide_providers.dart';
import 'package:mohingo/features/app_shell/presentation/app_shell_scaffold.dart';
import 'package:mohingo/features/app_shell/presentation/content_error_screen.dart';
import 'package:mohingo/features/legal/domain/legal_documents.dart';
import 'package:mohingo/features/legal/presentation/welcome_screen.dart';
import 'package:mohingo/features/review/providers/review_providers.dart';

import 'features/activity_engine/fake_connectivity_service.dart';

/// A returning learner's preferences: the agreement accepted and the app
/// guide seen, so the app opens straight on Home. [values] are added on
/// top; [firstLaunch] starts from nothing, as a fresh install does.
Future<SharedPreferences> _mockPrefs([
  Map<String, Object> values = const {},
  bool firstLaunch = false,
]) async {
  SharedPreferences.setMockInitialValues({
    if (!firstLaunch) ...{
      'legal.acceptedAgreementVersion': kAgreementVersion,
      'appGuide.completedVersion': kAppGuideVersion,
    },
    ...values,
  });
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
  AppDatabase? database,
  Future<void> Function()? onEachPump,
  bool Function()? until,
}) async {
  await tester.runAsync(() async {
    // Widget tests must never touch a real on-disk database: AppDatabase.
    // defaults() opens a real file via path_provider, which isn't mocked in
    // the widget-test environment and hangs. Override with an in-memory
    // instance instead — nothing here asserts on persisted progress.
    //
    // Likewise, MohingoApp watches pendingRefinementDrainerProvider at root
    // (Task 10), which reads/listens to the real DeviceConnectivityService's
    // connectivity_plus platform channel — also unmocked here, and reported
    // by the plugin as an unhandled MissingPluginException on both listen
    // and cancel. Override with a fake instead; nothing here exercises the
    // online-refinement drain.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(
            // Riverpod 3 rejects the same provider being overridden twice,
            // so a caller that wants to read the database back afterwards
            // passes it here rather than in `overrides`.
            database ?? AppDatabase(NativeDatabase.memory()),
          ),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: false),
          ),
          ...overrides,
        ],
        child: const MohingoApp(),
      ),
    );
    var shellFound = false;
    for (var i = 0; i < 100; i++) {
      shellFound |= find.byType(AppShellScaffold).evaluate().isNotEmpty;
      await onEachPump?.call();
      if (shellFound && (until?.call() ?? true)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
  });
  await tester.pump();
  // Fail here rather than letting a caller silently assert against the
  // splash screen if the bundle never finished loading.
  expect(find.byType(AppShellScaffold), findsOneWidget);
}

/// Pumps [MohingoApp] from [prefs] and keeps pumping, in real time, until
/// [until] finds something (or ~10 s pass). For start-up paths that do not
/// end on the shell, such as a first launch.
Future<void> _pumpAppUntil(
  WidgetTester tester,
  SharedPreferences prefs,
  Finder until,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: false),
          ),
        ],
        child: const MohingoApp(),
      ),
    );
    await _pumpRealTimeUntil(tester, until);
  });
  await tester.pump();
}

/// Pumps in real time until [finder] finds something, for at most ~10 s.
/// Must run inside [WidgetTester.runAsync].
Future<void> _pumpRealTimeUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Taps [finder] and lets the app settle in real time (the app guide
/// scrolls and measures its targets after a frame).
Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
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

  testWidgets('starting the app records the bundle it loaded', (tester) async {
    // content_versions was empty on every install until this landed: the
    // repository was fully implemented and had no callers at all.
    final prefs = await _mockPrefs();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    var rows = const <ContentVersion>[];
    await _pumpAppAndWaitForContent(
      tester,
      prefs,
      database: db,
      // Runs inside the helper's own runAsync loop, beside the wait for
      // the shell: the recorder's writes are real async and cannot
      // complete under the widget test's fake clock afterwards.
      onEachPump: () async => rows = await db.select(db.contentVersions).get(),
      until: () => rows.isNotEmpty,
    );

    expect(rows, hasLength(1));
    expect(rows.single.courseId, 'EN-A1-V2');
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

  testWidgets('a later level failing to load never gates the app', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(
      tester,
      prefs,
      overrides: [
        courseContentProvider('a2')
            .overrideWith((ref) async => throw StateError('A2 is broken')),
      ],
    );

    // The app is up: the gate never waited on A2. A level that fails to
    // load is handled on the screen that shows it, not at the front door.
    //
    // That isn't what this next line is checking, though: if the gate had
    // waited on A2, _pumpAppAndWaitForContent's own assertion above would
    // already have failed when AppShellScaffold never appeared. This line
    // covers the other failure — the gate surfacing a later level's error
    // as the app's own, via ContentErrorScreen.
    expect(find.byType(ContentErrorScreen), findsNothing);
  });

  testWidgets('a fresh install opens on the agreement, then Home with the '
      'app guide; finishing the guide remembers both', (tester) async {
    final prefs = await _mockPrefs(const {}, true);
    await _pumpAppUntil(tester, prefs, find.byType(WelcomeScreen));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShellScaffold), findsNothing);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WelcomeScreen)),
    )!;
    // Arabic by default, and the agreement says what leaves the phone.
    expect(find.text(l10n.welcomeWritingTitle), findsOneWidget);
    expect(find.text(l10n.welcomeSpeechTitle), findsOneWidget);

    await _tapAndSettle(tester, find.text(l10n.welcomeAccept));
    await tester.runAsync(
      () => _pumpRealTimeUntil(tester, find.text(l10n.guideIntroTitle)),
    );
    await tester.pump();

    expect(prefs.getInt('legal.acceptedAgreementVersion'), kAgreementVersion);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(AppShellScaffold), findsOneWidget);
    expect(find.text(l10n.guideIntroTitle), findsOneWidget);

    // Every step, forwards, then Done on the last.
    for (final title in [
      l10n.guideLevelTitle,
      l10n.guideContinueTitle,
      l10n.guideJourneyTitle,
      l10n.guideLearnTitle,
      l10n.guideReviewTitle,
      l10n.guideTestsTitle,
      l10n.guideSettingsTitle,
    ]) {
      await _tapAndSettle(tester, find.text(l10n.guideNext));
      expect(
        find.descendant(
          of: find.byType(AppGuideOverlay),
          matching: find.text(title),
        ),
        findsOneWidget,
        reason: 'guide step "$title"',
      );
    }
    expect(find.text(l10n.guideSkip), findsNothing);
    await _tapAndSettle(tester, find.text(l10n.guideDone));

    expect(find.text(l10n.guideSettingsBody), findsNothing);
    expect(prefs.getInt('appGuide.completedVersion'), kAppGuideVersion);
  });

  testWidgets('Skip closes the guide at once and remembers it', (tester) async {
    final prefs = await _mockPrefs(const {
      'legal.acceptedAgreementVersion': kAgreementVersion,
    }, true);
    await _pumpAppUntil(tester, prefs, find.byType(AppGuideOverlay));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppShellScaffold)),
    )!;
    await tester.runAsync(
      () => _pumpRealTimeUntil(tester, find.text(l10n.guideSkip)),
    );
    await tester.pump();

    await _tapAndSettle(tester, find.text(l10n.guideSkip));

    expect(find.text(l10n.guideIntroTitle), findsNothing);
    expect(prefs.getInt('appGuide.completedVersion'), kAppGuideVersion);
  });

  testWidgets('a returning learner sees neither the agreement nor the guide', (
    tester,
  ) async {
    final prefs = await _mockPrefs();
    await _pumpAppAndWaitForContent(tester, prefs);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppShellScaffold)),
    )!;

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text(l10n.guideIntroTitle), findsNothing);
  });

  testWidgets('an agreement accepted at an older version is asked for again, '
      'saying the documents changed', (tester) async {
    final prefs = await _mockPrefs(const {
      'legal.acceptedAgreementVersion': kAgreementVersion - 1,
      'appGuide.completedVersion': kAppGuideVersion,
    }, true);
    await _pumpAppUntil(tester, prefs, find.byType(WelcomeScreen));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WelcomeScreen)),
    )!;
    // Version 1 is the first: nobody has an older one yet, so there is no
    // notice. The screen itself is still the gate.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      find.text(l10n.welcomeUpdatedNotice),
      kAgreementVersion > 1 ? findsOneWidget : findsNothing,
    );
  });

  testWidgets('an upgrade from 0.1 drops the retired colour-theme setting', (
    tester,
  ) async {
    final prefs = await _mockPrefs({'settings.colorSeed': 'slateIndigo'});
    await removeRetiredPreferences(prefs);
    expect(prefs.containsKey('settings.colorSeed'), isFalse);
    // The rest of the learner's settings are untouched.
    expect(prefs.getInt('legal.acceptedAgreementVersion'), kAgreementVersion);
  });
}
