import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';
import 'package:mohingo/features/final_assessment/presentation/final_assessment_screen.dart';

void main() {
  testWidgets(
    'shows a percentage score per section and a next-step link when not passed',
    (tester) async {
      final results = [
        FinalAssessmentSectionResult(
          section: 'reading',
          status: FinalAssessmentSectionStatus.passed,
          averageScore: 0.9,
          scoredCount: 5,
          pendingReviewCount: 0,
        ),
        FinalAssessmentSectionResult(
          section: 'writing',
          status: FinalAssessmentSectionStatus.notMet,
          averageScore: 0.4,
          scoredCount: 3,
          pendingReviewCount: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: buildFinalAssessmentResultViewForTest(
            results: results,
            overallPassed: false,
            levelCode: 'A1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('90'), findsOneWidget);
      expect(find.textContaining('40'), findsOneWidget);

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.finalAssessmentWhatsNext), findsOneWidget);
    },
  );
}
