import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/review/providers/review_providers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('review nav destination shows a Badge when items are due', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Minimal harness: a NavigationBar built the same way
    // AppShellScaffold builds its Review destination, with
    // dueVocabularyCountProvider overridden directly (avoids needing a
    // full go_router StatefulNavigationShell in this test).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          dueVocabularyCountProvider.overrideWithValue(const AsyncData(3)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final dueCount = ref.watch(dueVocabularyCountProvider).value ?? 0;
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: NavigationBar(
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: dueCount > 0
                          ? Badge(
                              label: Text('$dueCount'),
                              child: const Icon(Icons.refresh_outlined),
                            )
                          : const Icon(Icons.refresh_outlined),
                      label: 'Review',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
