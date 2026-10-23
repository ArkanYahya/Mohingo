import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../domain/activity_submission.dart';

/// The lesson player's bottom bar before an answer is submitted: a
/// full-width Check button pinned to the bottom of the screen, in the
/// thumb zone, with an optional quieter [secondaryAction] under it.
class ActivityCheckBar extends StatelessWidget {
  const ActivityCheckBar({
    required this.canSubmit,
    required this.onSubmit,
    this.secondaryAction,
    super.key,
  });

  final bool canSubmit;
  final VoidCallback onSubmit;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.page,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: canSubmit ? onSubmit : null,
              child: Text(AppLocalizations.of(context)!.activitySubmitButton),
            ),
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpace.xxs),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The lesson player's feedback after Check: the bottom bar becomes this
/// panel, the same shape and place for every outcome, so the question
/// above stays visible with its right answer marked.
///
/// Correct is the semantic green and incorrect the error red — never the
/// brand colour, so "correct" reads the same whichever colour theme the
/// learner picked — and an answer that is saved rather than graded right
/// away gets a neutral panel. Every state pairs its colour with an icon
/// and a title, per docs/DESIGN_SYSTEM.md. The correct answer is only ever
/// shown here, after submission, for this activity. See
/// docs/ARCHITECTURE.md's non-negotiable rules.
class ActivityFeedbackPanel extends StatelessWidget {
  const ActivityFeedbackPanel({
    required this.submission,
    required this.onContinue,
    this.correctAnswerLabel,
    this.testMode = false,
    super.key,
  });

  final ActivitySubmission submission;
  final VoidCallback onContinue;

  /// Shown under "Not quite" when the activity has a fixed answer to
  /// reveal; open-ended rubrics have none, and the row is left out.
  final String? correctAnswerLabel;

  /// In a test the answer is saved, never marked: a neutral "Answer saved"
  /// panel, no right answer, and "Next question".
  final bool testMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final correctness = submission.pendingOnlineRefinement || testMode
        ? ActivityCorrectness.notAutoGraded
        : submission.correctness;
    final (
      Color background,
      Color foreground,
      Color badge,
      Color onBadge,
      IconData icon,
      String title,
      String? body,
    ) = switch (correctness) {
      ActivityCorrectness.correct => (
        feedback.successContainer,
        feedback.onSuccessContainer,
        feedback.success,
        feedback.onSuccess,
        Icons.check_rounded,
        l10n.activityFeedbackCorrect,
        null,
      ),
      ActivityCorrectness.incorrect => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        colorScheme.error,
        colorScheme.onError,
        Icons.close_rounded,
        l10n.activityFeedbackIncorrectTitle,
        null,
      ),
      ActivityCorrectness.notAutoGraded => (
        tokens.cardMuted,
        tokens.textPrimary,
        tokens.primaryInk,
        tokens.onPrimaryInk,
        testMode
            ? Icons.check_rounded
            : submission.pendingOnlineRefinement
            ? Icons.cloud_sync_rounded
            : Icons.hourglass_top_rounded,
        testMode ? l10n.testAnswerSaved : l10n.activityFeedbackSavedTitle,
        testMode
            ? l10n.testAnswerSavedBody
            : submission.pendingOnlineRefinement
            ? (submission.onlineRefinementAllowed
                  ? l10n.activityFeedbackPendingOnlineRefinement
                  : l10n.activityFeedbackPendingLocalJudgement)
            : l10n.activityFeedbackSavedForReview,
      ),
    };
    final answer = correctness == ActivityCorrectness.incorrect
        ? correctAnswerLabel
        : null;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.hero),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.md + AppSpace.xxs,
            AppSpace.md,
            AppSpace.md + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badge,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: onBadge, size: 22),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              if (answer != null && answer.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  l10n.activityFeedbackCorrectAnswerLabel.toUpperCase(),
                  style: overlineStyle(context, color: foreground),
                ),
                const SizedBox(height: 2),
                ContentText.en(
                  answer,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
              if (body != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
              if (!testMode &&
                  correctness != ActivityCorrectness.notAutoGraded) ...[
                ActivityExplanation(submission: submission, color: foreground),
              ],
              const SizedBox(height: AppSpace.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor:
                      correctness == ActivityCorrectness.notAutoGraded
                      ? null
                      : badge,
                  foregroundColor:
                      correctness == ActivityCorrectness.notAutoGraded
                      ? null
                      : onBadge,
                ),
                onPressed: onContinue,
                child: Text(
                  testMode ? l10n.testNextQuestion : l10n.activityContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The AI pack's explanation of a verdict (ADR 0013): an "Explanation"
/// overline, the English, the Arabic when the pack managed one, and the
/// "Generated on your phone" label that always accompanies it. Feedback
/// only — it never changes the verdict above it. Renders nothing when the
/// submission carries no explanation, which is every answer graded without
/// the pack.
class ActivityExplanation extends StatelessWidget {
  const ActivityExplanation({
    required this.submission,
    required this.color,
    super.key,
  });

  final ActivitySubmission submission;

  /// The text colour of the surface this sits on.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final en = submission.explanationEn;
    final ar = submission.explanationAr;
    if ((en == null || en.isEmpty) && (ar == null || ar.isEmpty)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.activityFeedbackExplanationLabel.toUpperCase(),
          style: overlineStyle(context, color: color),
        ),
        if (en != null && en.isNotEmpty) ...[
          const SizedBox(height: 2),
          ContentText.en(
            en,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
        if (ar != null && ar.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xxs),
          ContentText.ar(
            ar,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
        const SizedBox(height: AppSpace.xxs),
        Text(
          l10n.activityFeedbackGeneratedLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
