import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/vocabulary/presentation/vocabulary_list_screen.dart';

CourseContentIndex _realA1Index() {
  final json = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(json));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('word rows show a status indicator alongside the favorite star', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const VocabularyListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatusIndicator), findsWidgets);
  });

  testWidgets('the 3 stat tiles show the real Due/Learning/Learned counts, '
      'aggregated across both words and chunks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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

    final index = _realA1Index();
    final due = index.bundle.lexicon[0];
    final learning = index.bundle.lexicon[1];
    final learned = index.bundle.lexicon[2];
    final now = DateTime.now();

    await db
        .into(db.vocabularyReviewState)
        .insert(
          VocabularyReviewStateCompanion.insert(
            uuid: 'v1',
            learnerId: learnerId,
            lexiconId: Value(due.id),
            repetitions: const Value(1),
            dueAt: Value(now.subtract(const Duration(days: 1))),
            updatedAt: now,
          ),
        );
    await db
        .into(db.vocabularyReviewState)
        .insert(
          VocabularyReviewStateCompanion.insert(
            uuid: 'v2',
            learnerId: learnerId,
            lexiconId: Value(learning.id),
            repetitions: const Value(1),
            dueAt: Value(now.add(const Duration(days: 5))),
            updatedAt: now,
          ),
        );
    await db
        .into(db.vocabularyReviewState)
        .insert(
          VocabularyReviewStateCompanion.insert(
            uuid: 'v3',
            learnerId: learnerId,
            lexiconId: Value(learned.id),
            repetitions: const Value(3),
            dueAt: Value(now.add(const Duration(days: 30))),
            updatedAt: now,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const VocabularyListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(VocabularyListScreen)),
    )!;
    expect(find.text(l10n.vocabularyStatDue), findsOneWidget);
    expect(find.text(l10n.vocabularyStatLearning), findsOneWidget);
    expect(find.text(l10n.vocabularyStateLearned), findsOneWidget);
    // Each of the 3 seeded rows lands in a different bucket, so every
    // stat tile's count is exactly 1.
    expect(find.text('1'), findsNWidgets(3));
  });

  testWidgets(
    'the saved-words row shows the real favourited count, across both '
    'words and chunks',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
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

      final index = _realA1Index();
      final favoriteWord = index.bundle.lexicon[0];
      final favoriteChunk = index.bundle.chunks[0];

      await db
          .into(db.vocabularyReviewState)
          .insert(
            VocabularyReviewStateCompanion.insert(
              uuid: 'v1',
              learnerId: learnerId,
              lexiconId: Value(favoriteWord.id),
              isFavorite: const Value(true),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );
      await db
          .into(db.vocabularyReviewState)
          .insert(
            VocabularyReviewStateCompanion.insert(
              uuid: 'v2',
              learnerId: learnerId,
              chunkId: Value(favoriteChunk.id),
              isFavorite: const Value(true),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _realA1Index()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const VocabularyListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(VocabularyListScreen)),
      )!;
      expect(find.text(l10n.vocabularySavedWordsTitle), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'a learned word row\'s circular icon fills with the semantic success '
    'colour, not colorScheme.primary',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
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

      final index = _realA1Index();
      final learned = index.bundle.lexicon[0];
      final now = DateTime.now();

      await db
          .into(db.vocabularyReviewState)
          .insert(
            VocabularyReviewStateCompanion.insert(
              uuid: 'v1',
              learnerId: learnerId,
              lexiconId: Value(learned.id),
              repetitions: const Value(3),
              dueAt: Value(now.add(const Duration(days: 30))),
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _realA1Index()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const VocabularyListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final feedbackTheme = Theme.of(
        tester.element(find.byType(VocabularyListScreen)),
      ).extension<FeedbackTheme>()!;
      final colorScheme = Theme.of(
        tester.element(find.byType(VocabularyListScreen)),
      ).colorScheme;

      // The circle isn't an ancestor of the headword text — they're
      // siblings under the same row — so find that row first, then look
      // for the circular Container among its descendants.
      final rowFinder = find
          .ancestor(of: find.text(learned.headword), matching: find.byType(Row))
          .first;
      final circle = tester.widget<Container>(
        find.descendant(
          of: rowFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle,
          ),
        ),
      );
      final decoration = circle.decoration! as BoxDecoration;
      expect(decoration.color, feedbackTheme.success);
      expect(decoration.color, isNot(equals(colorScheme.primary)));
    },
  );
}
