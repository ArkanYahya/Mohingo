import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/app_tokens.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(AppColorSeed.warmTerracotta),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

/// An [ActivityChrome] hosted the way the lesson player hosts it — inside
/// an [ActivityFrameScope] — with [feedback] as its bottom slot.
Widget _framed({
  required Widget feedback,
  VoidCallback? onContinue,
  Widget? header,
}) {
  return ActivityFrameScope(
    onContinue: onContinue ?? () {},
    header: header,
    child: ActivityChrome(
      prompt: 'Choose the answer.',
      promptAr: 'اختر الإجابة.',
      body: const SizedBox(height: 40),
      feedback: feedback,
    ),
  );
}

Color? _panelColor(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(
            of: find.byType(ActivityFeedbackPanel),
            matching: find.byType(Material),
          )
          .first,
    )
    .color;

void main() {
  group('ActivityFeedbackBanner (inline, outside the lesson player)', () {
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

    testWidgets('an incorrect submission uses colorScheme.errorContainer', (
      tester,
    ) async {
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

  group('ActivitySubmitOrFeedback outside the lesson player', () {
    testWidgets('shows an inline Check button before submission, and the '
        'inline banner — never the docked panel — after it', (tester) async {
      await _pump(
        tester,
        const ActivitySubmitOrFeedback(
          submission: null,
          canSubmit: true,
          onSubmit: _noop,
        ),
      );
      final l10n = _l10n(tester);
      expect(
        find.widgetWithText(FilledButton, l10n.activitySubmitButton),
        findsOneWidget,
      );
      expect(find.byType(ActivityCheckBar), findsNothing);

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
      expect(find.byType(ActivityFeedbackPanel), findsNothing);
    });

    testWidgets('a secondary action sits under Check until the answer is '
        'submitted', (tester) async {
      await _pump(
        tester,
        ActivitySubmitOrFeedback(
          submission: null,
          canSubmit: false,
          onSubmit: _noop,
          secondaryAction: TextButton(
            onPressed: () {},
            child: const Text('Type instead'),
          ),
        ),
      );
      expect(find.text('Type instead'), findsOneWidget);

      await _pump(
        tester,
        ActivitySubmitOrFeedback(
          submission: const ActivitySubmission(
            correctness: ActivityCorrectness.correct,
          ),
          canSubmit: false,
          onSubmit: _noop,
          secondaryAction: TextButton(
            onPressed: () {},
            child: const Text('Type instead'),
          ),
        ),
      );
      expect(find.text('Type instead'), findsNothing);
    });
  });

  group('inside the lesson player (ActivityFrameScope)', () {
    testWidgets('before submission: a Check bar pinned to the bottom of the '
        'screen, disabled until an answer is ready', (tester) async {
      var submitted = 0;
      await _pump(
        tester,
        _framed(
          feedback: ActivitySubmitOrFeedback(
            submission: null,
            canSubmit: false,
            onSubmit: () => submitted++,
          ),
        ),
      );
      final l10n = _l10n(tester);

      expect(find.byType(ActivityCheckBar), findsOneWidget);
      final screen = tester.getSize(find.byType(Scaffold));
      expect(
        tester.getBottomLeft(find.byType(ActivityCheckBar)).dy,
        screen.height,
      );

      final check = find.widgetWithText(
        FilledButton,
        l10n.activitySubmitButton,
      );
      expect(tester.widget<FilledButton>(check).onPressed, isNull);

      await _pump(
        tester,
        _framed(
          feedback: ActivitySubmitOrFeedback(
            submission: null,
            canSubmit: true,
            onSubmit: () => submitted++,
          ),
        ),
      );
      await tester.tap(check);
      expect(submitted, 1);
    });

    testWidgets('a correct answer turns the bar into the success feedback '
        'panel, whose Continue calls the host\'s onContinue', (tester) async {
      var continued = 0;
      await _pump(
        tester,
        _framed(
          onContinue: () => continued++,
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.correct,
            ),
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );
      final l10n = _l10n(tester);
      final feedbackTheme = Theme.of(tester.element(find.byType(Scaffold)))
          .extension<FeedbackTheme>()!;

      expect(find.byType(ActivityFeedbackPanel), findsOneWidget);
      expect(find.byType(ActivityCheckBar), findsNothing);
      expect(find.byType(ActivityFeedbackBanner), findsNothing);
      expect(find.text(l10n.activityFeedbackCorrect), findsOneWidget);
      expect(_panelColor(tester), feedbackTheme.successContainer);

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.activityContinue),
      );
      expect(continued, 1);
    });

    testWidgets('a wrong answer shows "Not quite" and the correct answer in '
        'the same panel, in error colours — no modal sheet', (tester) async {
      await _pump(
        tester,
        _framed(
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.incorrect,
            ),
            canSubmit: false,
            onSubmit: _noop,
            correctAnswerLabel: 'Omar',
          ),
        ),
      );
      final l10n = _l10n(tester);
      final colorScheme = Theme.of(tester.element(find.byType(Scaffold)))
          .colorScheme;

      expect(find.text(l10n.activityFeedbackIncorrectTitle), findsOneWidget);
      expect(
        find.text(l10n.activityFeedbackCorrectAnswerLabel.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Omar'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Omar')).textDirection,
        TextDirection.ltr,
      );
      expect(_panelColor(tester), colorScheme.errorContainer);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('a wrong answer to an open-ended question (no fixed answer '
        'to reveal) shows no correct-answer row', (tester) async {
      await _pump(
        tester,
        _framed(
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.incorrect,
            ),
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );
      final l10n = _l10n(tester);

      expect(find.text(l10n.activityFeedbackIncorrectTitle), findsOneWidget);
      expect(
        find.text(l10n.activityFeedbackCorrectAnswerLabel.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('an answer saved for review says so in a neutral panel', (
      tester,
    ) async {
      await _pump(
        tester,
        _framed(
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.notAutoGraded,
            ),
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );
      final l10n = _l10n(tester);
      final tokens = Theme.of(tester.element(find.byType(Scaffold)))
          .extension<AppTokens>()!;

      expect(find.text(l10n.activityFeedbackSavedTitle), findsOneWidget);
      expect(find.text(l10n.activityFeedbackSavedForReview), findsOneWidget);
      expect(_panelColor(tester), tokens.cardMuted);
    });

    testWidgets('an answer queued for online checking says so', (tester) async {
      await _pump(
        tester,
        _framed(
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.notAutoGraded,
              pendingOnlineRefinement: true,
            ),
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );
      final l10n = _l10n(tester);

      expect(find.text(l10n.activityFeedbackSavedTitle), findsOneWidget);
      expect(
        find.text(l10n.activityFeedbackPendingOnlineRefinement),
        findsOneWidget,
      );
    });

    testWidgets('the panel is announced to screen readers as a live region', (
      tester,
    ) async {
      await _pump(
        tester,
        _framed(
          feedback: const ActivitySubmitOrFeedback(
            submission: ActivitySubmission(
              correctness: ActivityCorrectness.correct,
            ),
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(ActivityFeedbackPanel),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.liveRegion ?? false),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('ActivityChrome', () {
    testWidgets('inside the lesson player it shows the host\'s header line '
        'above the prompt, in the prompt\'s larger style', (tester) async {
      await _pump(
        tester,
        _framed(
          header: const Text('PRACTICE · READING'),
          feedback: const ActivitySubmitOrFeedback(
            submission: null,
            canSubmit: false,
            onSubmit: _noop,
          ),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));

      expect(find.text('PRACTICE · READING'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('PRACTICE · READING')).dy,
        lessThan(tester.getTopLeft(find.text('Choose the answer.')).dy),
      );
      expect(
        tester.widget<Text>(find.text('Choose the answer.')).style?.fontSize,
        theme.textTheme.titleLarge!.fontSize,
      );
    });

    for (final (locale, name) in [
      (const Locale('en'), 'LTR'),
      (const Locale('ar'), 'RTL'),
    ]) {
      testWidgets('the Arabic prompt starts at the same edge as the English '
          'prompt ($name layout)', (tester) async {
        await _pump(
          tester,
          const ActivityChrome(
            prompt: 'Choose the answer.',
            promptAr: 'اختر الإجابة.',
            body: SizedBox.shrink(),
          ),
          locale: locale,
        );
        final en = find.text('Choose the answer.');
        final ar = find.text('اختر الإجابة.');
        if (locale.languageCode == 'ar') {
          expect(tester.getTopRight(ar).dx, tester.getTopRight(en).dx);
        } else {
          expect(tester.getTopLeft(ar).dx, tester.getTopLeft(en).dx);
        }
      });
    }
  });
}

void _noop() {}
