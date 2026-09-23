import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/account/domain/auth_repository.dart';
import 'package:mohingo/features/account/presentation/auth_screen.dart';
import 'package:mohingo/features/account/providers/account_providers.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';

import 'fake_auth_repository.dart';

void main() {
  late AppDatabase db;
  late FakeAuthRepository auth;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = FakeAuthRepository()..accounts['sara@example.com'] = 'secret-1';
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (_, _) => const Scaffold(body: Text('settings')),
        ),
        GoRoute(
          path: '/account/sign-in',
          builder: (_, _) => const AuthScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    router.push('/account/sign-in');
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(AuthScreen)));
  }

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('checks the form before asking the server', (tester) async {
    await pump(tester);
    await fill(tester, 'not-an-email', '');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('a wrong password shows a plain message, never a raw error', (
    tester,
  ) async {
    await pump(tester);
    await fill(tester, 'sara@example.com', 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('the Arabic interface explains an offline failure in Arabic', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('ar'));
    auth.nextFailure = AuthFailure.network;
    await fill(tester, 'sara@example.com', 'secret-1');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا يوجد اتصال بالإنترنت'), findsOneWidget);
  });

  testWidgets('signing in closes the screen and binds the account', (
    tester,
  ) async {
    final container = await pump(tester);
    await fill(tester, 'sara@example.com', 'secret-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsNothing);
    expect(find.text('Signed in. Your progress will sync.'), findsOneWidget);
    expect(
      container.read(accountSessionProvider).value,
      isA<SignedInSession>(),
    );
  });

  testWidgets('a phone with guest progress asks before adding it to the '
      'account', (tester) async {
    final guest = await DriftLearnerRepository(db).getOrCreateLearner();
    await DriftActivityAttemptRepository(db).recordAttempt(
      learnerId: guest.id,
      activityId: 'A1-U1-L1-A01',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
    );
    final container = await pump(tester);
    await fill(tester, 'sara@example.com', 'secret-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text("Add this phone's progress to your account?"),
      findsOneWidget,
    );
    await tester.tap(find.text('Add to my account'));
    await tester.pumpAndSettle();

    final session = container.read(accountSessionProvider).value;
    expect(session, isA<SignedInSession>());
    expect(session!.learnerId, guest.id);
  });

  testWidgets('create-account mode asks for the password twice', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'abcdef');
    await tester.enterText(find.byType(TextFormField).at(2), 'abcdeg');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text("The passwords don't match."), findsOneWidget);
    expect(auth.accounts, isNot(contains('new@example.com')));
  });
}
