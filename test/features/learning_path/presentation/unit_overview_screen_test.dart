import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
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
import 'package:mohingo/features/learning_path/presentation/unit_overview_screen.dart';
import 'package:mohingo/features/learning_path/providers/unit_progress_providers.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

// The brief's sample helper returned `CourseBundleParser.parse(json)`
// directly (a `CourseBundle`), but `courseContentProvider` — and this
// screen under test — expects a `CourseContentIndex` (it reads
// `index.unitsById`/`index.bundle.units`). `CourseContentIndex.build` also
// runs the unresolved-reference validation the real content-loading path
// performs. See the identical fixture pattern in
// test/features/learning_path/presentation/unit_path_view_test.dart.
Future<CourseContentIndex> _realA1Index() async {
  final json = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  final bundle = CourseBundleParser.parse(json);
  return CourseContentIndex.build(bundle);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'shows one StatusIndicator per non-mission lesson in the unit — a '
    'mission-type lesson gets its own distinct card (a flag icon, not a '
    "StatusIndicator), matching Learn's unit-spine milestone treatment",
    (tester) async {
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

      final index = await _realA1Index();
      final unit = index.bundle.units.first;

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
            home: UnitOverviewScreen(unitId: unit.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nonMissionCount = unit.lessons
          .where((l) => l.lessonType != 'mission')
          .length;
      expect(find.byType(StatusIndicator), findsNWidgets(nonMissionCount));
    },
  );

  // Guards the Fix-1 contract: invalidation of lessonProgressForUnitProvider
  // is owned by LessonPlayerScreen (which can leave by pop *or*
  // pushReplacement), and this screen must pick the fresh value up purely
  // through its `ref.watch`, with no Navigator event of its own. The old
  // design — `await context.push(...)` then invalidate — could not do this,
  // because go_router's `pushReplacement` never completes the replaced
  // route's future.
  testWidgets(
    'picks up a lesson finished elsewhere when the shared provider is '
    'invalidated, and labels it "Completed", not "Mastered"',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final index = await _realA1Index();
      final unit = index.bundle.units.firstWhere(
        (u) => u.lessons.any((l) => l.activities.isNotEmpty),
      );
      final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);
      final lessonRow = unit.lessons.indexOf(lesson);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _realA1Index()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: UnitOverviewScreen(unitId: unit.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      StatusIndicator indicatorAt(int i) => tester
          .widgetList<StatusIndicator>(find.byType(StatusIndicator))
          .elementAt(i);

      expect(indicatorAt(lessonRow).state, ProgressState.notStarted);

      // Exactly what LessonPlayerScreen._next() does once the last activity
      // is answered: persist the position, then invalidate — from a route
      // this screen never hears back from.
      final learner = await container.read(currentLearnerProvider.future);
      await container
          .read(unitLessonProgressRepositoryProvider)
          .recordLessonPosition(
            learnerId: learner.id,
            lessonId: lesson.id,
            unitId: unit.id,
            lastActivityId: lesson.activities.last.id,
          );
      container.invalidate(
        lessonProgressForUnitProvider((learnerId: learner.id, unitId: unit.id)),
      );
      await tester.pumpAndSettle();

      expect(indicatorAt(lessonRow).state, ProgressState.mastered);
      expect(indicatorAt(lessonRow).semanticLabelOverride, 'Completed');
    },
  );

  testWidgets('a finished lesson with a wrong answer shows needsReview, not '
      'mastered — the reported bug: "2 wrong" still showed the finished icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final index = await _realA1Index();
    final unit = index.bundle.units.firstWhere(
      (u) => u.lessons.any((l) => l.activities.isNotEmpty),
    );
    final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);
    final lessonRow = unit.lessons.indexOf(lesson);
    final firstActivity = lesson.activities.first;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _realA1Index()),
      ],
    );
    addTearDown(container.dispose);
    final learner = await container.read(currentLearnerProvider.future);

    // Finish the lesson, but with its first activity recorded wrong.
    await container
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: learner.id,
          activityId: firstActivity.id,
          lessonId: lesson.id,
          sessionType: 'lesson',
          mode: ActivityMode.mastery,
          evidenceSkill: firstActivity.skill,
          canDoIds: firstActivity.canDo,
          isCorrect: false,
        );
    await container
        .read(unitLessonProgressRepositoryProvider)
        .recordLessonPosition(
          learnerId: learner.id,
          lessonId: lesson.id,
          unitId: unit.id,
          lastActivityId: lesson.activities.last.id,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: UnitOverviewScreen(unitId: unit.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = tester
        .widgetList<StatusIndicator>(find.byType(StatusIndicator))
        .elementAt(lessonRow);
    expect(indicator.state, ProgressState.needsReview);
    // needsReview keeps StatusIndicator's own default label — no
    // "Completed" override, unlike the all-correct mastered case.
    expect(indicator.semanticLabelOverride, null);
  });

  group('lesson-row tap routing', () {
    GoRouter testRouter({required Widget Function() home}) {
      return GoRouter(
        initialLocation: '/unit-test',
        routes: [
          GoRoute(path: '/unit-test', builder: (_, _) => home()),
          GoRoute(
            path: '/lesson-player/:unitId/:lessonId',
            builder: (_, _) => const Scaffold(body: Text('LESSON_PLAYER_STUB')),
          ),
          GoRoute(
            path: '/lesson-review/:unitId/:lessonId',
            builder: (_, _) => const Scaffold(body: Text('LESSON_REVIEW_STUB')),
          ),
        ],
      );
    }

    testWidgets('a not-started lesson still routes to the real lesson player, '
        'unaffected', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final index = await _realA1Index();
      final unit = index.bundle.units.firstWhere(
        (u) => u.lessons.any((l) => l.activities.isNotEmpty),
      );
      final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _realA1Index()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            routerConfig: testRouter(
              home: () => UnitOverviewScreen(unitId: unit.id),
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(lesson.title).first);
      await tester.pumpAndSettle();

      expect(find.text('LESSON_PLAYER_STUB'), findsOneWidget);
    });

    testWidgets('a finished lesson routes to the read-only review screen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final index = await _realA1Index();
      final unit = index.bundle.units.firstWhere(
        (u) => u.lessons.any((l) => l.activities.isNotEmpty),
      );
      final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _realA1Index()),
        ],
      );
      addTearDown(container.dispose);
      final learner = await container.read(currentLearnerProvider.future);

      await container
          .read(unitLessonProgressRepositoryProvider)
          .recordLessonPosition(
            learnerId: learner.id,
            lessonId: lesson.id,
            unitId: unit.id,
            lastActivityId: lesson.activities.last.id,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            routerConfig: testRouter(
              home: () => UnitOverviewScreen(unitId: unit.id),
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(lesson.title).first);
      await tester.pumpAndSettle();

      expect(find.text('LESSON_REVIEW_STUB'), findsOneWidget);
    });
  });

  testWidgets(
    'the header shows "N of M lessons complete", starting at 0 of the '
    "unit's total lesson count",
    (tester) async {
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

      final index = await _realA1Index();
      final unit = index.unitsById['A1-U0']!;

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
            home: UnitOverviewScreen(unitId: unit.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(UnitOverviewScreen)),
      )!;
      expect(
        find.text(l10n.unitOverviewLessonsComplete(0, unit.lessons.length)),
        findsOneWidget,
      );
    },
  );

  testWidgets('with no progress at all, the first lesson is highlighted as the '
      "current one to do next — a later, also-not-started lesson isn't", (
    tester,
  ) async {
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

    final index = await _realA1Index();
    final unit = index.unitsById['A1-U0']!;
    final firstLesson = unit.lessons.first;
    final laterLesson = unit.lessons[1];

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
          home: UnitOverviewScreen(unitId: unit.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final colorScheme = Theme.of(
      tester.element(find.byType(UnitOverviewScreen)),
    ).colorScheme;

    Color? rowColorFor(String title) {
      final container = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(title).first,
              matching: find.byType(Container),
            ),
          )
          .first;
      return (container.decoration! as BoxDecoration).color;
    }

    expect(rowColorFor(firstLesson.title), colorScheme.primaryContainer);
    expect(rowColorFor(laterLesson.title), isNot(colorScheme.primaryContainer));
  });

  testWidgets(
    'a mastered lesson row is tinted with the semantic success container '
    'colour',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final index = await _realA1Index();
      final unit = index.unitsById['A1-U0']!;
      final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _realA1Index()),
        ],
      );
      addTearDown(container.dispose);
      final learner = await container.read(currentLearnerProvider.future);

      for (final activity in lesson.activities) {
        await container
            .read(activityAttemptRepositoryProvider)
            .recordAttempt(
              learnerId: learner.id,
              activityId: activity.id,
              lessonId: lesson.id,
              sessionType: 'lesson',
              mode: ActivityMode.mastery,
              evidenceSkill: activity.skill,
              canDoIds: activity.canDo,
              isCorrect: true,
            );
      }
      await container
          .read(unitLessonProgressRepositoryProvider)
          .recordLessonPosition(
            learnerId: learner.id,
            lessonId: lesson.id,
            unitId: unit.id,
            lastActivityId: lesson.activities.last.id,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: UnitOverviewScreen(unitId: unit.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final feedbackTheme = Theme.of(
        tester.element(find.byType(UnitOverviewScreen)),
      ).extension<FeedbackTheme>()!;
      final rowContainer = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(lesson.title).first,
              matching: find.byType(Container),
            ),
          )
          .first;
      expect(
        (rowContainer.decoration! as BoxDecoration).color,
        feedbackTheme.successContainer,
      );
    },
  );

  testWidgets(
    'a mission-type lesson (A1-U0-L5) renders as a solid, vivid card, not '
    'the ordinary row treatment',
    (tester) async {
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

      final index = await _realA1Index();
      final unit = index.unitsById['A1-U0']!;
      final mission = unit.lessons.firstWhere((l) => l.lessonType == 'mission');
      expect(
        mission.id,
        'A1-U0-L5',
        reason:
            'this test is written against the real content shape — if '
            'A1-U0 changes, update the assumption here alongside it',
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
            home: UnitOverviewScreen(unitId: unit.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colorScheme = Theme.of(
        tester.element(find.byType(UnitOverviewScreen)),
      ).colorScheme;
      final rowContainer = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(mission.title).first,
              matching: find.byType(Container),
            ),
          )
          .first;
      expect(
        (rowContainer.decoration! as BoxDecoration).color,
        colorScheme.primary,
      );
    },
  );
}
