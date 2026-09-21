import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
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
import 'package:mohingo/core/l10n/skill_label.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';
import 'package:mohingo/features/final_assessment/presentation/final_assessment_screen.dart';
import 'package:mohingo/features/final_mission/domain/final_mission_scoring.dart';
import 'package:mohingo/features/final_mission/presentation/final_mission_screen.dart';
import 'package:mohingo/features/placement_test/domain/placement_outcome.dart';
import 'package:mohingo/features/placement_test/domain/placement_plan.dart';
import 'package:mohingo/features/placement_test/presentation/placement_test_screen.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);
final _a2Index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
  ),
);

final _plan = PlacementPlan.across([
  PlacementLevel(levelId: 'a1', cefrCode: 'A1', units: _index.bundle.units),
  PlacementLevel(levelId: 'a2', cefrCode: 'A2', units: _a2Index.bundle.units),
]);

late AppDatabase _db;

/// Pumps [view] as a pushed page over a stub home, with a stub unit page.
///
/// A placement result can move the learner into another level when it is
/// tapped, so this brings up the real learner database and content
/// providers rather than a bare MaterialApp.
Future<AppLocalizations> _pump(WidgetTester tester, Widget view) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _db = AppDatabase(NativeDatabase.memory());
  addTearDown(_db.close);
  final router = GoRouter(
    initialLocation: '/tests',
    routes: [
      GoRoute(
        path: '/tests',
        builder: (_, _) => const Text('TESTS'),
        routes: [GoRoute(path: 'result', builder: (_, _) => view)],
      ),
      GoRoute(
        path: '/learn/unit/:id',
        builder: (_, s) => Text('UNIT ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/learn', builder: (_, _) => const Text('LEARN')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(_db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
        courseContentProvider('a2').overrideWith((ref) async => _a2Index),
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
  router.push('/tests/result');
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('placement result', () {
    testWidgets('leads with the unit to start from, shows it as a card, '
        'and "Start at" opens it', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startFromRecommendedUnit,
            recommendedUnitId: 'A1-U3',
          ),
          recommendation: _plan.locate('A1-U3'),
          masteredLevelCode: 'A2',
          skillScores: {Skill.listening: (5, 6), Skill.reading: (7, 9)},
        ),
      );

      expect(find.text(l10n.placementResultHeadline('A1', 4)), findsOneWidget);
      expect(find.text(_index.unitsById['A1-U3']!.title), findsOneWidget);
      expect(find.text(l10n.testsSkillScore(5, 6)), findsOneWidget);
      expect(find.text(skillLabel(l10n, Skill.reading)), findsOneWidget);
      expect(find.text(l10n.placementResultEarlierOpen), findsOneWidget);

      await tester.tap(find.text(l10n.placementResultStartAtUnit('A1', 4)));
      await tester.pumpAndSettle();
      expect(find.text('UNIT A1-U3'), findsOneWidget);
    });

    testWidgets('"start with essentials" is Unit 1, by number not id', (
      tester,
    ) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startWithEssentials,
            recommendedUnitId: 'A1-U0',
          ),
          recommendation: _plan.locate('A1-U0'),
          masteredLevelCode: 'A2',
          skillScores: const {},
        ),
      );

      expect(find.text(l10n.placementResultHeadline('A1', 1)), findsOneWidget);
      expect(find.text(l10n.placementResultEarlierOpen), findsNothing);
    });

    testWidgets('an A2 result is numbered inside A2 — A2-U5 is Unit 5, not '
        'Unit 6 and never Unit 0', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startFromRecommendedUnit,
            recommendedUnitId: 'A2-U5',
          ),
          recommendation: _plan.locate('A2-U5'),
          masteredLevelCode: 'A2',
          skillScores: const {},
        ),
      );

      expect(find.text(l10n.placementResultHeadline('A2', 5)), findsOneWidget);
      expect(find.text(_a2Index.unitsById['A2-U5']!.title), findsOneWidget);
    });

    testWidgets('"Start at" makes that level current, unlocks it, and opens '
        'the unit', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startFromRecommendedUnit,
            recommendedUnitId: 'A2-U5',
          ),
          recommendation: _plan.locate('A2-U5'),
          masteredLevelCode: 'A2',
          skillScores: const {},
        ),
      );

      await tester.tap(find.text(l10n.placementResultStartAtUnit('A2', 5)));
      await tester.pumpAndSettle();

      expect(find.text('UNIT A2-U5'), findsOneWidget);
      final enrolments = await _db.select(_db.courseEnrolments).get();
      final a2 = enrolments.singleWhere((e) => e.levelId == 'a2');
      expect(
        a2.lastSelectedAt,
        isNotNull,
        reason: 'the placement result makes that level the current one',
      );
      expect(
        a2.unlockedAt,
        isNotNull,
        reason: 'a result inside A2 opens A2, locked or not',
      );
    });

    testWidgets('a level mastered has no unit card, names the level it '
        'measured, and Done closes', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.levelMastered,
            masteredLevelId: 'a2',
          ),
          recommendation: null,
          masteredLevelCode: 'A2',
          skillScores: const {},
        ),
      );

      expect(
        find.text(l10n.placementResultMasteredTitle('A2')),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.placementResultDone));
      await tester.pumpAndSettle();
      expect(find.text('TESTS'), findsOneWidget);
    });

    testWidgets('a level start reads as the beginning of that level, not as '
        'a gap inside it', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startFromRecommendedUnit,
            recommendedUnitId: 'A2-U1',
          ),
          recommendation: _plan.locate('A2-U1'),
          masteredLevelCode: 'A2',
          skillScores: const {},
        ),
      );

      expect(
        find.text(l10n.placementResultBodyLevelStart('A2')),
        findsOneWidget,
      );
    });
  });

  group('final mission result', () {
    testWidgets('names each skill group with its result', (tester) async {
      final l10n = await _pump(
        tester,
        buildFinalMissionResultViewForTest(
          const FinalMissionScoringResult(
            passed: false,
            groupResults: [
              SkillGroupResult(
                skills: ['listening'],
                passed: true,
                averageScore: 0.9,
                scoredEvidenceCount: 3,
                pendingReviewCount: 0,
              ),
              SkillGroupResult(
                skills: ['writing'],
                passed: false,
                averageScore: 0,
                scoredEvidenceCount: 0,
                pendingReviewCount: 2,
              ),
              SkillGroupResult(
                skills: ['spokenInteraction'],
                passed: false,
                averageScore: 0.3,
                scoredEvidenceCount: 3,
                pendingReviewCount: 0,
              ),
            ],
          ),
        ),
      );

      expect(find.text(l10n.missionResultNotYetTitle), findsOneWidget);
      expect(find.text(l10n.finalAssessmentSkillPassed), findsOneWidget);
      expect(find.text(l10n.testsWaitingReview), findsOneWidget);
      expect(find.text(l10n.finalAssessmentSkillNotMet), findsOneWidget);
    });
  });

  group('final assessment result', () {
    testWidgets('each skill shows its score against the pass mark', (
      tester,
    ) async {
      final l10n = await _pump(
        tester,
        buildFinalAssessmentResultViewForTest(
          results: [
            FinalAssessmentSectionResult(
              section: 'reading',
              status: FinalAssessmentSectionStatus.passed,
              averageScore: 0.9,
              scoredCount: 16,
              pendingReviewCount: 0,
            ),
            FinalAssessmentSectionResult(
              section: 'writing',
              status: FinalAssessmentSectionStatus.pendingReview,
              averageScore: 0,
              scoredCount: 0,
              pendingReviewCount: 2,
            ),
          ],
          overallPassed: false,
          levelCode: 'A1',
          passMarks: const {'reading': 0.6, 'writing': 0.6},
        ),
      );

      expect(find.text(l10n.assessmentResultNotYetTitle), findsOneWidget);
      expect(find.text(l10n.assessmentResultBody(1, 2)), findsOneWidget);
      expect(find.text(l10n.testsScorePassMark(90, 60)), findsOneWidget);
      expect(find.text(l10n.testsWaitingReview), findsOneWidget);
      expect(find.text(l10n.testsPendingBody), findsOneWidget);
    });
  });
}
