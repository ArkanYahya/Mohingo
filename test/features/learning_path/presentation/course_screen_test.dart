import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/course_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// With [midCourse]: Unit 1 (A1-U0) mastered, and in A1-U1 the first two
/// lessons finished and the third started. Otherwise a brand-new learner.
Future<AppDatabase> _seed({required bool midCourse}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final learner = await db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(uuid: 'l', createdAt: DateTime.utc(2026)),
      );
  if (!midCourse) return db;
  final now = DateTime.utc(2026, 9, 18);
  await db
      .into(db.unitProgress)
      .insert(
        UnitProgressCompanion.insert(
          uuid: 'u0',
          learnerId: learner,
          unitId: 'A1-U0',
          state: 'mastered',
          updatedAt: now,
        ),
      );
  final u1 = _index.unitsById['A1-U1']!;
  for (final (i, finished) in [(0, true), (1, true), (2, false)]) {
    final lesson = u1.lessons[i];
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            uuid: 'lp$i',
            learnerId: learner,
            lessonId: lesson.id,
            unitId: 'A1-U1',
            state: finished ? 'completed' : 'inProgress',
            lastActivityId: Value(
              finished ? lesson.activities.last.id : lesson.activities.first.id,
            ),
            lastPositionUpdatedAt: Value(now.add(Duration(minutes: i))),
            updatedAt: now,
          ),
        );
  }
  return db;
}

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  bool midCourse = true,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = await _seed(midCourse: midCourse);
  addTearDown(db.close);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/learn',
    routes: [
      GoRoute(path: '/learn', builder: (_, _) => const CourseScreen()),
      GoRoute(
        path: '/learn/unit/:unitId',
        builder: (_, s) => Text('UNIT ${s.pathParameters['unitId']}'),
      ),
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, s) => Text(
          'PLAYER ${s.pathParameters['unitId']} ${s.pathParameters['lessonId']}',
        ),
      ),
      GoRoute(path: '/tests', builder: (_, _) => const Text('TESTS')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(CourseScreen)))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('opens on the course: its title in English and Arabic, units '
      'mastered over total, and every unit on the path', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text('English A1'), findsOneWidget);
    expect(find.text(_index.bundle.course.titleAr), findsOneWidget);
    expect(find.text(l10n.homeLevelProgressCaption(1, 13)), findsOneWidget);
    for (final unit in _index.bundle.units) {
      expect(find.text(unit.title), findsOneWidget, reason: unit.id);
    }
  });

  testWidgets('the unit being worked on is the one highlighted card — its '
      'lessons done, the next lesson, and Continue lesson opens the player', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    expect(
      find.text(l10n.learnUnitInProgressOverline(2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.learnUnitLessonsDone(2, 7)), findsOneWidget);
    expect(
      find.textContaining(_index.lessonsById['A1-U1-L3']!.title),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.homeContinueLessonCta));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER A1-U1 A1-U1-L3'), findsOneWidget);
  });

  testWidgets('a new learner starts on the first unit, with Start lesson', (
    tester,
  ) async {
    final l10n = await _pump(tester, midCourse: false);

    expect(
      find.text(l10n.learnUnitStartHereOverline(1).toUpperCase()),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.homeStartLessonCta));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER A1-U0 A1-U0-L1'), findsOneWidget);
  });

  testWidgets('a mastered unit says so; a unit not started shows its size '
      'and time; the starter unit is tagged', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.unitStateMastered), findsOneWidget);
    expect(find.text(l10n.learnUnitStarter.toUpperCase()), findsOneWidget);
    final u2 = _index.unitsById['A1-U2']!;
    expect(
      find.text(
        '${l10n.learnLessonCount(u2.lessons.length)} · '
        '${l10n.learnUnitMinutes(u2.estimatedMinutes[0], u2.estimatedMinutes[1])}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('each unit\'s circle is announced with its number and state', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    expect(
      find.bySemanticsLabel(
        l10n.learnUnitNodeSemantics(1, l10n.unitStateMastered),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        l10n.learnUnitNodeSemantics(3, l10n.unitStateNotStarted),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a unit opens its unit page', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(_index.unitsById['A1-U3']!.title));
    await tester.pumpAndSettle();
    expect(find.text('UNIT A1-U3'), findsOneWidget);
  });

  testWidgets('the path ends at the final mission & assessment, which opens '
      'the Tests tab', (tester) async {
    final l10n = await _pump(tester);

    await tester.tap(find.text(l10n.learnFinishTitle));
    await tester.pumpAndSettle();
    expect(find.text('TESTS'), findsOneWidget);
  });

  testWidgets('the other levels are listed as coming later, never as '
      'tappable rows', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.learnComingLaterTitle.toUpperCase()), findsOneWidget);
    for (final code in ['A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(find.text(code), findsOneWidget);
      expect(
        find.bySemanticsLabel('$code — ${l10n.comingSoon}'),
        findsOneWidget,
      );
    }
    expect(
      find.ancestor(of: find.text('A2'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });
}
