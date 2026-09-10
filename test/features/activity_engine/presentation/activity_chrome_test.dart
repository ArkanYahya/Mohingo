import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(AppColorSeed.warmTerracotta),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ActivityFeedbackBanner', () {
    testWidgets(
      'a correct submission fills with the semantic success colour, not '
      "colorScheme.primaryContainer — otherwise 'correct' would read as "
      "warmTerracotta's orange instead of a universal green",
      (tester) async {
        await _pump(
          tester,
          const ActivityFeedbackBanner(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.correct,
            ),
          ),
        );

        final context = tester.element(find.byType(Container));
        final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
        final colorScheme = Theme.of(context).colorScheme;

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, feedbackTheme.successContainer);
        expect(decoration.color, isNot(equals(colorScheme.primaryContainer)));

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, feedbackTheme.onSuccessContainer);
      },
    );

    testWidgets('an incorrect submission still uses colorScheme.error, '
        'unchanged', (tester) async {
      await _pump(
        tester,
        const ActivityFeedbackBanner(
          submission: ActivitySubmission(
            correctness: ActivityCorrectness.incorrect,
          ),
          correctAnswerLabel: 'answer',
        ),
      );

      final context = tester.element(find.byType(Container));
      final colorScheme = Theme.of(context).colorScheme;

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, colorScheme.errorContainer);
    });
  });

  group('ActivitySubmitOrFeedback', () {
    testWidgets(
      'suppressIncorrectBanner hides the incorrect banner entirely — the '
      'live lesson player shows a bottom sheet instead, so the inline '
      "banner would just duplicate it",
      (tester) async {
        await _pump(
          tester,
          const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.incorrect,
            ),
            canSubmit: false,
            onSubmit: _noop,
            correctAnswerLabel: 'answer',
            suppressIncorrectBanner: true,
          ),
        );

        expect(find.byType(ActivityFeedbackBanner), findsNothing);
      },
    );

    testWidgets('suppressIncorrectBanner leaves a correct submission\'s banner '
        'untouched — only the incorrect case is ever suppressed', (
      tester,
    ) async {
      await _pump(
        tester,
        const ActivitySubmitOrFeedback(
          submission: ActivitySubmission(
            correctness: ActivityCorrectness.correct,
          ),
          canSubmit: false,
          onSubmit: _noop,
          suppressIncorrectBanner: true,
        ),
      );

      expect(find.byType(ActivityFeedbackBanner), findsOneWidget);
    });

    testWidgets(
      'suppressIncorrectBanner defaults to false — review mode (which never '
      'passes it) keeps showing the inline incorrect banner as before',
      (tester) async {
        await _pump(
          tester,
          const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.incorrect,
            ),
            canSubmit: false,
            onSubmit: _noop,
            correctAnswerLabel: 'answer',
          ),
        );

        expect(find.byType(ActivityFeedbackBanner), findsOneWidget);
      },
    );
  });
}

void _noop() {}
