import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/unit_overview_screen.dart';
import 'package:mohingo/features/learning_path/presentation/widgets/path_row.dart';
import 'package:mohingo/features/learning_path/providers/unit_progress_providers.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// The unit page for [unitId] on real content, inside a router with stub
/// player and review routes. [seed] runs against the container first.
Future<(ProviderContainer, AppLocalizations)> _pump(
  WidgetTester tester, {
  String unitId = 'A1-U1',
  Future<void> Function(ProviderContainer container, int learnerId)? seed,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      courseContentProvider('a1').overrideWith((ref) async => _index),
    ],
  );
  addTearDown(container.dispose);
  final learner = await container.read(currentLearnerProvider.future);
  if (seed != null) await seed(container, learner.id);

  final router = GoRouter(
    initialLocation: '/unit',
    routes: [
      GoRoute(
        path: '/unit',
        builder: (_, _) => UnitOverviewScreen(unitId: unitId),
      ),
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, s) => Text('PLAYER ${s.pathParameters['lessonId']}'),
      ),
      GoRoute(
        path: '/lesson-review/:unitId/:lessonId',
        builder: (_, s) => Text('REVIEW ${s.pathParameters['lessonId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    container,
    AppLocalizations.of(tester.element(find.byType(UnitOverviewScreen)))!,
  );
}

Future<void> _finish(
  ProviderContainer container,
  int learnerId,
  Lesson lesson, {
  bool allCorrect = true,
}) async {
  for (final (i, activity) in lesson.activities.indexed) {
    await container
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: learnerId,
          activityId: activity.id,
          lessonId: lesson.id,
          sessionType: 'lesson',
          mode: ActivityMode.mastery,
          evidenceSkill: activity.skill,
          canDoIds: activity.canDo,
          isCorrect: allCorrect || i > 0,
        );
  }
  await container
      .read(unitLessonProgressRepositoryProvider)
      .recordLessonPosition(
        learnerId: learnerId,
        lessonId: lesson.id,
        unitId: lesson.id.substring(0, lesson.id.lastIndexOf('-')),
        lastActivityId: lesson.activities.last.id,
      );
}

PathNode _nodeFor(WidgetTester tester, String semanticsLabel) => tester
    .widgetList<PathNode>(find.byType(PathNode))
    .firstWhere((n) => n.semanticsLabel == semanticsLabel);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final unit = _index.unitsById['A1-U1']!;

  testWidgets('the header names the unit, its size and time, and lessons '
      'complete', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.text(l10n.learnUnitOverline(2).toUpperCase()), findsOneWidget);
    expect(find.text(unit.title), findsOneWidget);
    expect(find.text(unit.titleAr), findsOneWidget);
    expect(
      find.text(
        '${l10n.learnLessonCount(7)} · '
        '${l10n.learnUnitMinutes(unit.estimatedMinutes[0], unit.estimatedMinutes[1])}',
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.unitOverviewLessonsComplete(0, 7)), findsOneWidget);
  });

  testWidgets('one node per lesson on the path — numbered, with the unit '
      'mission as a flag', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.byType(PathNode), findsNWidgets(unit.lessons.length));
    final mission = unit.lessons.last;
    expect(mission.lessonType, 'mission');
    expect(
      _nodeFor(
        tester,
        l10n.learnLessonNodeSemantics(7, l10n.unitStateNotStarted),
      ).kind,
      PathNodeKind.flag,
    );
    expect(find.text(l10n.learnMissionOverline.toUpperCase()), findsOneWidget);
    expect(find.textContaining(l10n.learnMissionBody), findsOneWidget);
  });

  testWidgets('with nothing played, lesson 1 is the one highlighted card — '
      'Start here, and Start lesson opens the player', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(
      find.text(l10n.learnLessonStartHereOverline(1).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.homeStartLessonCta), findsOneWidget);
    expect(
      _nodeFor(
        tester,
        l10n.learnLessonNodeSemantics(1, l10n.unitStateNotStarted),
      ).kind,
      PathNodeKind.current,
    );

    await tester.tap(find.text(l10n.homeStartLessonCta));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER A1-U1-L1'), findsOneWidget);
  });

  testWidgets('a lesson part-way through is the current card with Continue '
      'lesson; the finished one before it says it can be reviewed', (
    tester,
  ) async {
    final (_, l10n) = await _pump(
      tester,
      seed: (container, learnerId) async {
        await _finish(container, learnerId, unit.lessons[0]);
        await container
            .read(unitLessonProgressRepositoryProvider)
            .recordLessonPosition(
              learnerId: learnerId,
              lessonId: unit.lessons[1].id,
              unitId: unit.id,
              lastActivityId: unit.lessons[1].activities.first.id,
            );
      },
    );

    expect(
      find.text(l10n.learnLessonInProgressOverline(2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.homeContinueLessonCta), findsOneWidget);
    expect(find.text(l10n.learnLessonCompletedReview), findsOneWidget);
    expect(find.text(l10n.unitOverviewLessonsComplete(1, 7)), findsOneWidget);
    expect(
      _nodeFor(
        tester,
        l10n.learnLessonNodeSemantics(1, l10n.lessonStateCompleted),
      ).kind,
      PathNodeKind.done,
    );
  });

  testWidgets('a finished lesson whose latest answers include a mistake gets '
      'its own node and says there are answers to revisit', (tester) async {
    final (_, l10n) = await _pump(
      tester,
      seed: (container, learnerId) =>
          _finish(container, learnerId, unit.lessons[0], allCorrect: false),
    );

    expect(
      _nodeFor(
        tester,
        l10n.learnLessonNodeSemantics(1, l10n.unitStateNeedsReview),
      ).kind,
      PathNodeKind.review,
    );
    expect(find.text(l10n.learnLessonNeedsReviewReview), findsOneWidget);
  });

  testWidgets('upcoming lessons show their type and size, with an icon on '
      'those that open with a conversation', (tester) async {
    final (_, l10n) = await _pump(tester);

    final lesson = unit.lessons[3]; // A1-U1-L4 "He and She", no dialogue
    expect(
      find.text(
        '${l10n.homeLessonTypeGuided} · '
        '${l10n.homeActivityCount(lesson.activities.length)}',
      ),
      findsWidgets,
    );
    final withConversation = unit.lessons
        .where((l) => l.encounterDialogue.isNotEmpty)
        .length;
    expect(
      find.bySemanticsLabel(l10n.learnLessonHasConversation),
      findsNWidgets(withConversation),
    );
  });

  testWidgets('picks up a lesson finished elsewhere when the shared provider '
      'is invalidated', (tester) async {
    final (container, l10n) = await _pump(tester);
    final learner = await container.read(currentLearnerProvider.future);

    await _finish(container, learner.id, unit.lessons[0]);
    container.invalidate(
      lessonProgressForUnitProvider((learnerId: learner.id, unitId: unit.id)),
    );
    container.invalidate(
      lessonAttemptsForUnitProvider((learnerId: learner.id, unitId: unit.id)),
    );
    await tester.pumpAndSettle();

    expect(
      _nodeFor(
        tester,
        l10n.learnLessonNodeSemantics(1, l10n.lessonStateCompleted),
      ).kind,
      PathNodeKind.done,
    );
  });

  group('tapping a lesson', () {
    testWidgets('a not-started lesson opens the lesson player', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(unit.lessons[3].title));
      await tester.pumpAndSettle();
      expect(find.text('PLAYER A1-U1-L4'), findsOneWidget);
    });

    testWidgets('a finished lesson opens its answer review', (tester) async {
      await _pump(
        tester,
        seed: (container, learnerId) =>
            _finish(container, learnerId, unit.lessons[0]),
      );

      await tester.tap(find.text(unit.lessons[0].title));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW A1-U1-L1'), findsOneWidget);
    });
  });
}
