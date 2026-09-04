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
import 'package:mohingo/features/tests_home/presentation/tests_home_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Widget> wrapped(AppDatabase db) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const TestsHomeScreen(),
      ),
    );
  }

  testWidgets('placement card shows "not yet taken" with no attempt', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(await wrapped(db));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TestsHomeScreen)),
    )!;
    expect(find.text(l10n.testsHomeNotYetTaken), findsWidgets);
  });

  testWidgets('placement card shows a completed date after an attempt', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
    await db
        .into(db.placementAttempts)
        .insert(
          PlacementAttemptsCompanion.insert(
            uuid: 'pa-1',
            learnerId: learnerId,
            startedAt: DateTime.utc(2026, 9, 2),
            completedAt: const Value(null),
          ),
        );
    await (db.update(
      db.placementAttempts,
    )..where((t) => t.learnerId.equals(learnerId))).write(
      PlacementAttemptsCompanion(
        completedAt: Value(DateTime.utc(2026, 9, 2)),
        outcome: const Value('a1FromU1'),
      ),
    );

    await tester.pumpWidget(await wrapped(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed'), findsOneWidget);
  });
}
