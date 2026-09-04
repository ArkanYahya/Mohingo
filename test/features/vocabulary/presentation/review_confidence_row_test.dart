import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/vocabulary/presentation/review_confidence_row.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'shows a saved confirmation then pops back after tapping a confidence button',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('push'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: ReviewConfidenceRow(
                            lexiconId: 'A1.LEX.HELLO.INTJ',
                          ),
                        ),
                      ),
                    ),
                    child: const Text('open word'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('push')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ReviewConfidenceRow)),
      )!;
      await tester.tap(find.text(l10n.reviewQualityGood));
      await tester.pump();

      expect(find.text(l10n.reviewConfidenceSaved), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('open word'), findsOneWidget);
      expect(find.byType(ReviewConfidenceRow), findsNothing);
    },
  );
}
