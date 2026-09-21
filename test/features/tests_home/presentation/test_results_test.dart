import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/skill_label.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';
import 'package:mohingo/features/final_assessment/presentation/final_assessment_screen.dart';
import 'package:mohingo/features/final_mission/domain/final_mission_scoring.dart';
import 'package:mohingo/features/final_mission/presentation/final_mission_screen.dart';
import 'package:mohingo/features/placement_test/domain/placement_outcome.dart';
import 'package:mohingo/features/placement_test/presentation/placement_test_screen.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// Pumps [view] as a pushed page over a stub home, with a stub unit page.
Future<AppLocalizations> _pump(WidgetTester tester, Widget view) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
    MaterialApp.router(
      theme: AppTheme.light(AppColorSeed.calmTeal),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
  router.push('/tests/result');
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
}

void main() {
  group('placement result', () {
    testWidgets('leads with the unit to start from, shows it as a card, '
        'and Go to Unit opens it', (tester) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.startFromRecommendedUnit,
            recommendedUnitId: 'A1-U3',
          ),
          units: _index.bundle.units,
          skillScores: {Skill.listening: (5, 6), Skill.reading: (7, 9)},
        ),
      );

      expect(find.text(l10n.placementResultHeadline(4)), findsOneWidget);
      expect(find.text(_index.unitsById['A1-U3']!.title), findsOneWidget);
      expect(find.text(l10n.testsSkillScore(5, 6)), findsOneWidget);
      expect(find.text(skillLabel(l10n, Skill.reading)), findsOneWidget);
      expect(find.text(l10n.placementResultEarlierOpen), findsOneWidget);

      await tester.tap(find.text(l10n.placementResultGoToUnitN(4)));
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
          units: _index.bundle.units,
          skillScores: const {},
        ),
      );

      expect(find.text(l10n.placementResultHeadline(1)), findsOneWidget);
      expect(find.text(l10n.placementResultEarlierOpen), findsNothing);
    });

    testWidgets('A1 mastered has no unit card, and Done closes', (
      tester,
    ) async {
      final l10n = await _pump(
        tester,
        buildPlacementResultViewForTest(
          classification: const PlacementClassification(
            outcome: PlacementOutcome.a1Mastered,
          ),
          units: _index.bundle.units,
          skillScores: const {},
        ),
      );

      expect(find.text(l10n.placementResultMasteredTitle), findsOneWidget);
      await tester.tap(find.text(l10n.placementResultDone));
      await tester.pumpAndSettle();
      expect(find.text('TESTS'), findsOneWidget);
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
