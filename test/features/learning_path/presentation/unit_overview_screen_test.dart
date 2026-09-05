import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
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

  testWidgets('shows one StatusIndicator per lesson in the unit', (
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
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: UnitOverviewScreen(unitId: unit.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatusIndicator), findsNWidgets(unit.lessons.length));
  });

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
}
