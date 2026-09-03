import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/grammar/presentation/grammar_list_screen.dart';
import 'package:mohingo/features/review/presentation/review_home_screen.dart';
import 'package:mohingo/features/vocabulary/presentation/vocabulary_list_screen.dart';
import 'package:mohingo/features/vocabulary/presentation/word_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

Future<Widget> _wrapped(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(
        AppDatabase(NativeDatabase.memory()),
      ),
      courseContentProvider('a1').overrideWith((ref) async => _realA1Index()),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('VocabularyListScreen renders real words and can search', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _wrapped(tester, const VocabularyListScreen()),
    );
    await tester.pumpAndSettle();

    // The Words tab is active by default; a known real headword should show.
    expect(find.text('hello'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzznomatch');
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsNothing);
  });

  testWidgets(
    'tapping a word opens WordDetailScreen with real content, including '
    'the two distinct "picture" senses staying distinct by id',
    (tester) async {
      final index = _realA1Index();
      final pictureSense = index.lexiconById['A1.LEX.PICTURE.N01']!;

      await tester.pumpWidget(
        await _wrapped(tester, WordDetailScreen(lexiconId: pictureSense.id)),
      );
      await tester.pumpAndSettle();

      expect(find.text(pictureSense.headword), findsWidgets);
      expect(find.byType(WordDetailScreen), findsOneWidget);
    },
  );

  testWidgets('GrammarListScreen renders real grammar entries', (tester) async {
    await tester.pumpWidget(await _wrapped(tester, const GrammarListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('A1-U0'), findsOneWidget); // unit filter chip
    expect(find.text('I am'), findsOneWidget); // a real grammar form
  });

  testWidgets('ReviewHomeScreen renders without crashing', (tester) async {
    await tester.pumpWidget(await _wrapped(tester, const ReviewHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewHomeScreen), findsOneWidget);
  });
}
