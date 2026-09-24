import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/account/domain/auth_repository.dart';
import 'package:mohingo/features/account/presentation/delete_account_flow.dart';
import 'package:mohingo/features/account/providers/account_providers.dart';
import 'package:mohingo/features/sync/providers/sync_providers.dart';

import 'fake_auth_repository.dart';

/// The delete-account dialogs: each kind of account confirms who it is the
/// way it signs in, and only then is it deleted.
void main() {
  late AppDatabase db;
  late FakeAuthRepository auth;
  late int deletions;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    deletions = 0;
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(auth),
          deleteAccountProvider.overrideWithValue(() async => deletions++),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(accountSessionProvider).value?.user;
                if (user == null) return const Text('loading');
                return TextButton(
                  onPressed: () => runDeleteAccountFlow(context),
                  child: const Text('start'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("Confirm it's you"), findsOneWidget);
  }

  Finder confirmButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, label),
  );

  testWidgets('an Apple account confirms with Apple, not a password', (
    tester,
  ) async {
    auth = FakeAuthRepository(
      signedIn: FakeAuthRepository.appleUser,
      supportsApple: true,
    );
    await pump(tester);
    expect(
      find.text("To delete the account, confirm with Apple that it's you."),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    // A red button may not be dressed as Sign in with Apple.
    expect(find.text('Continue with Apple'), findsNothing);

    await tester.tap(confirmButton('Delete account'));
    await tester.pumpAndSettle();

    expect(auth.reauthenticatedWith, [AuthProvider.apple]);
    expect(deletions, 1);
    expect(find.text('Your account has been deleted.'), findsOneWidget);
  });

  testWidgets('closing the Apple sheet deletes nothing and shows no error', (
    tester,
  ) async {
    auth = FakeAuthRepository(
      signedIn: FakeAuthRepository.appleUser,
      supportsApple: true,
    );
    await pump(tester);
    auth.nextFailure = AuthFailure.cancelled;
    await tester.tap(confirmButton('Delete account'));
    await tester.pumpAndSettle();

    expect(deletions, 0);
    expect(find.text("Confirm it's you"), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsNothing);
  });

  testWidgets('a Google account picks its Google account again', (
    tester,
  ) async {
    auth = FakeAuthRepository(
      signedIn: const AuthUser(
        uid: 'uid-g',
        email: 'g@example.com',
        providers: {AuthProvider.google},
      ),
    );
    await pump(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(confirmButton('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.reauthenticatedWith, [AuthProvider.google]);
    expect(deletions, 1);
  });

  testWidgets('an email account confirms with its password', (tester) async {
    auth = FakeAuthRepository(
      signedIn: const AuthUser(
        uid: 'uid-e',
        email: 'e@example.com',
        providers: {AuthProvider.emailPassword},
      ),
    )..accounts['e@example.com'] = 'pw-e';
    await pump(tester);
    expect(
      find.text('To delete the account, enter the password for e@example.com.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'pw-e');
    await tester.tap(confirmButton('Delete account'));
    await tester.pumpAndSettle();

    expect(auth.reauthenticatedWith, [AuthProvider.emailPassword]);
    expect(deletions, 1);
  });
}
