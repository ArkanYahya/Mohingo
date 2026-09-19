import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/tests_home/presentation/tests_home_screen.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);
final _mission = _index.bundle.finalMission;
final _assessment = _index.bundle.finalAssessment;
final _taken = DateTime(2026, 9, 12, 10);

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, int learnerId)? seed,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final learnerId = await db
      .into(db.learners)
      .insert(LearnersCompanion.insert(uuid: 'l', createdAt: DateTime(2026)));
  if (seed != null) await seed(db, learnerId);

  final router = GoRouter(
    initialLocation: '/tests',
    routes: [
      GoRoute(path: '/tests', builder: (_, _) => const TestsHomeScreen()),
      for (final name in ['placement', 'final-mission', 'final-assessment'])
        GoRoute(path: '/tests/$name', builder: (_, _) => Text('OPEN $name')),
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
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(TestsHomeScreen)))!;
}

Future<void> _seedPlacement(
  AppDatabase db,
  int learnerId, {
  required String outcome,
  String? unitId,
}) => db
    .into(db.placementAttempts)
    .insert(
      PlacementAttemptsCompanion.insert(
        uuid: 'p',
        learnerId: learnerId,
        startedAt: _taken,
        completedAt: Value(_taken),
        outcome: Value(outcome),
        recommendedUnitId: Value(unitId),
      ),
    );

Future<void> _seedLessonPlayed(AppDatabase db, int learnerId) => db
    .into(db.lessonProgress)
    .insert(
      LessonProgressCompanion.insert(
        uuid: 'lp',
        learnerId: learnerId,
        lessonId: 'A1-U0-L1',
        unitId: 'A1-U0',
        state: 'inProgress',
        updatedAt: _taken,
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a brand-new learner is pointed at the placement test first', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    expect(
      find.text(l10n.testsStartHereOverline.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.testsPlacementHeroTitle), findsOneWidget);

    await tester.tap(find.text(l10n.testsPlacementCta));
    await tester.pumpAndSettle();
    expect(find.text('OPEN placement'), findsOneWidget);
  });

  testWidgets('once lessons are under way, placement is a plain row, not '
      'the highlighted card', (tester) async {
    final l10n = await _pump(tester, seed: _seedLessonPlayed);

    expect(find.text(l10n.testsStartHereOverline.toUpperCase()), findsNothing);
    expect(find.text(l10n.testsPlacementTitle), findsOneWidget);
    expect(find.text(l10n.testsNotTaken), findsNWidgets(3));
  });

  testWidgets('a finished placement test shows when it was taken and its '
      'result as a unit number', (tester) async {
    final l10n = await _pump(
      tester,
      seed: (db, id) => _seedPlacement(
        db,
        id,
        outcome: 'startFromRecommendedUnit',
        unitId: 'A1-U3',
      ),
    );

    expect(
      find.text(l10n.testsTakenOn(DateFormat.yMMMd('en').format(_taken))),
      findsOneWidget,
    );
    expect(find.text(l10n.testsPlacementResultUnit(4)), findsOneWidget);
  });

  testWidgets('"start with essentials" and "A1 mastered" results read as '
      'Unit 1 and as already mastered', (tester) async {
    final l10n = await _pump(
      tester,
      seed: (db, id) => _seedPlacement(db, id, outcome: 'startWithEssentials'),
    );
    expect(find.text(l10n.testsPlacementResultUnit(1)), findsOneWidget);
  });

  testWidgets('Finish A1: course progress, then the mission and the '
      'assessment with their real size and time', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.testsFinishOverline.toUpperCase()), findsOneWidget);
    expect(
      find.text(l10n.testsFinishProgress(0, _index.bundle.units.length)),
      findsOneWidget,
    );
    expect(find.text(_mission.title), findsOneWidget);
    expect(
      find.text(
        l10n.testsMissionMeta(
          _mission.activities.length,
          _mission.stages.length,
          _mission.estimatedMinutes[0],
          _mission.estimatedMinutes[1],
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(_assessment.title), findsOneWidget);
    final questions = _assessment.sections.values.fold<int>(
      0,
      (n, s) => n + s.activities.length,
    );
    expect(
      find.text(
        l10n.testsAssessmentMeta(
          questions,
          _assessment.sections.length,
          _assessment.estimatedMinutes[0],
          _assessment.estimatedMinutes[1],
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(_mission.title));
    await tester.pumpAndSettle();
    expect(find.text('OPEN final-mission'), findsOneWidget);
  });

  testWidgets('finished mission and assessment show their results', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      seed: (db, id) async {
        await db
            .into(db.finalMissionAttempts)
            .insert(
              FinalMissionAttemptsCompanion.insert(
                uuid: 'm',
                learnerId: id,
                courseId: 'c',
                startedAt: _taken,
                completedAt: Value(_taken),
                outcome: const Value('passed'),
              ),
            );
        await db
            .into(db.finalAssessmentAttempts)
            .insert(
              FinalAssessmentAttemptsCompanion.insert(
                uuid: 'a',
                learnerId: id,
                courseId: 'c',
                startedAt: _taken,
                completedAt: Value(_taken),
                sectionResults: Value(
                  jsonEncode([
                    for (final (i, s) in [
                      'listening',
                      'reading',
                      'writing',
                      'speaking',
                      'mediation',
                    ].indexed)
                      {'section': s, 'status': i < 3 ? 'passed' : 'notMet'},
                  ]),
                ),
                outcomeSummary: Value(jsonEncode({'overallPassed': false})),
              ),
            );
      },
    );

    expect(find.text(l10n.testsPassed), findsOneWidget);
    expect(find.text(l10n.testsSkillsPassed(3, 5)), findsOneWidget);
  });

  testWidgets('no dead-end cards: the unit checks are a note, and later '
      'levels are not listed', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.testsUnitChecksNote), findsOneWidget);
    expect(find.textContaining('A2'), findsNothing);
  });
}
