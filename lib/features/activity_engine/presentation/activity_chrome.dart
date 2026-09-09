import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../domain/activity_submission.dart';

/// The shared shell every activity view renders inside: prompt, an optional
/// help area, the type-specific interaction body, and post-submission
/// feedback — consistent across all 9 activity types. See
/// docs/ARCHITECTURE.md's lesson-player requirements.
///
/// [prompt] (English) and [promptAr] (Arabic) are rendered as two separate
/// `Text` widgets, each given its own explicit `textDirection` — this is
/// deliberate: it avoids ever concatenating the two languages into one
/// string, which is what "preserve English punctuation and text direction
/// inside Arabic screens" is actually protecting against. Within
/// [promptAr] itself, an embedded Latin word/phrase (e.g. quoting an English
/// term) is handled correctly by Flutter's built-in Unicode Bidi Algorithm
/// support — no manual span-splitting needed or attempted here.
class ActivityChrome extends StatelessWidget {
  const ActivityChrome({
    required this.prompt,
    this.promptAr,
    this.help,
    required this.body,
    this.feedback,
    super.key,
  });

  final String prompt;
  final String? promptAr;
  final Widget? help;
  final Widget body;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            prompt,
            style: theme.textTheme.titleMedium,
            textDirection: TextDirection.ltr,
          ),
          if (promptAr != null) ...[
            const SizedBox(height: 4),
            Text(
              promptAr!,
              style: theme.textTheme.bodyMedium,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (help != null) ...[const SizedBox(height: 8), help!],
          const SizedBox(height: 16),
          body,
          if (feedback != null) ...[const SizedBox(height: 16), feedback!],
        ],
      ),
    );
  }
}

/// The correct/incorrect/saved-for-review banner — never colour alone, per
/// docs/DESIGN_SYSTEM.md: every state pairs a `colorScheme` role with an
/// icon and text.
class ActivityFeedbackBanner extends StatelessWidget {
  const ActivityFeedbackBanner({
    required this.submission,
    this.correctAnswerLabel,
    super.key,
  });

  final ActivitySubmission submission;

  /// The correct answer, in display form — only ever shown *after*
  /// submission, for *this* activity, never before submission and never for
  /// any other activity. Required when [submission].correctness is
  /// [ActivityCorrectness.incorrect]; ignored otherwise. See
  /// docs/ARCHITECTURE.md's non-negotiable rules.
  final String? correctAnswerLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    final (
      Color background,
      Color onColor,
      IconData icon,
      String label,
    ) = submission.pendingOnlineRefinement
        ? (
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurface,
            Icons.cloud_sync,
            l10n.activityFeedbackPendingOnlineRefinement,
          )
        : switch (submission.correctness) {
            // A real green, not colorScheme.primaryContainer — "correct"
            // reads as universal success, independent of which brand
            // colour theme the learner picked. See FeedbackTheme.
            ActivityCorrectness.correct => (
              feedbackTheme.successContainer,
              feedbackTheme.onSuccessContainer,
              Icons.check_circle,
              l10n.activityFeedbackCorrect,
            ),
            ActivityCorrectness.incorrect => (
              colorScheme.errorContainer,
              colorScheme.onErrorContainer,
              Icons.cancel,
              l10n.activityFeedbackIncorrectWithAnswer(
                correctAnswerLabel ?? '',
              ),
            ),
            ActivityCorrectness.notAutoGraded => (
              colorScheme.surfaceContainerHighest,
              colorScheme.onSurface,
              Icons.hourglass_top,
              l10n.activityFeedbackSavedForReview,
            ),
          };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: onColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: onColor)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The [ActivityChrome.feedback] slot's standard content: a disabled-until-
/// ready submit button before submission, the [ActivityFeedbackBanner]
/// after. Shared across every activity view so the submit/feedback
/// transition is consistent, per docs/ARCHITECTURE.md.
class ActivitySubmitOrFeedback extends StatelessWidget {
  const ActivitySubmitOrFeedback({
    required this.submission,
    required this.canSubmit,
    required this.onSubmit,
    this.correctAnswerLabel,
    super.key,
  });

  /// Null before the learner has submitted an answer.
  final ActivitySubmission? submission;

  /// Whether the submit button is currently enabled (e.g. an option is
  /// selected, or a text field is non-empty).
  final bool canSubmit;
  final VoidCallback onSubmit;
  final String? correctAnswerLabel;

  @override
  Widget build(BuildContext context) {
    final submission = this.submission;
    if (submission != null) {
      return ActivityFeedbackBanner(
        submission: submission,
        correctAnswerLabel: correctAnswerLabel,
      );
    }
    return FilledButton(
      onPressed: canSubmit ? onSubmit : null,
      child: Text(AppLocalizations.of(context)!.activitySubmitButton),
    );
  }
}
