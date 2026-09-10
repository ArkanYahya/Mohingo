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
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/home/presentation/home_screen.dart';
import 'package:mohingo/features/progress/domain/repositories/daily_task_event_repository.dart';
import 'package:uuid/uuid.dart';

Future<CourseContentIndex> _realA1Index() async {
  final json = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(json));
}

Future<Widget> _wrapped(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      courseContentProvider('a1').overrideWith((ref) async => _realA1Index()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorSeed.calmTeal),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows streak, continue, progress, and review-due cards', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(await _wrapped(db));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsNothing);
    // Streak card renders even with 0 days.
    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;
    expect(find.text(l10n.homeStreakTitle(0)), findsOneWidget);

    // The progress and review-due cards are further down the list now that
    // "Tasks today" adds real height above them — scroll to each in turn,
    // the way a learner would.
    await tester.scrollUntilVisible(
      find.textContaining('progress'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('progress'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text(l10n.homeReviewDueTitle(0)),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text(l10n.homeReviewDueTitle(0)), findsOneWidget);
  });

  testWidgets(
    'shows the 3 tasks-today tiles at 0/target, filled with the brand '
    "primary colour — no task is done yet, so none reads as green",
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(await _wrapped(db));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      )!;
      expect(find.text(l10n.homeTasksTodayTitle), findsOneWidget);
      expect(find.text(l10n.homeTaskFinishLesson), findsOneWidget);
      expect(find.text(l10n.homeTaskReviewWords), findsOneWidget);
      expect(find.text(l10n.homeTaskSpeakOnce), findsOneWidget);
      expect(find.text('0/1'), findsNWidgets(2)); // lesson + speaking
      expect(find.text('0/5'), findsOneWidget); // vocabulary review

      final colorScheme = Theme.of(tester.element(find.byType(HomeScreen)))
          .colorScheme;
      final tile = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(l10n.homeTaskFinishLesson),
              matching: find.byType(Container),
            ),
          )
          .first;
      final decoration = tile.decoration! as BoxDecoration;
      expect(decoration.color, colorScheme.primary);
    },
  );

  testWidgets(
    'a task tile that reached its target today turns the semantic success '
    'green, not the brand primary colour',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-1',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.dailyTaskEvents)
          .insert(
            DailyTaskEventsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              taskType: DailyTaskType.speaking.name,
              occurredAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(await _wrapped(db));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      )!;
      final feedbackTheme = Theme.of(tester.element(find.byType(HomeScreen)))
          .extension<FeedbackTheme>()!;
      expect(find.text('1/1'), findsOneWidget);
      final tile = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(l10n.homeTaskSpeakOnce),
              matching: find.byType(Container),
            ),
          )
          .first;
      final decoration = tile.decoration! as BoxDecoration;
      expect(decoration.color, feedbackTheme.success);
    },
  );

  testWidgets('the Continue-learning hero card is filled with the vivid brand '
      'primary colour, not the paler primaryContainer', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(await _wrapped(db));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;
    final colorScheme = Theme.of(tester.element(find.byType(HomeScreen)))
        .colorScheme;
    final card = tester.widget<Card>(
      find.ancestor(
        of: find.text(l10n.continueLearningTitle),
        matching: find.byType(Card),
      ),
    );
    expect(card.color, colorScheme.primary);
  });
}
