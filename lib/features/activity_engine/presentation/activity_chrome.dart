import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/widgets/content_text.dart';
import '../domain/activity_submission.dart';
import 'activity_feedback_panel.dart';
import 'widgets/activity_source_card.dart';

export 'activity_feedback_panel.dart';

/// Marks an activity as hosted full-screen in the question frame — by the
/// lesson player, and by the placement test, final mission and final
/// assessment (through `TestQuestionFrame`).
///
/// Inside this scope [ActivityChrome] becomes the question frame —
/// [header] above the prompt, the question scrolling, and the feedback
/// slot pinned to the bottom of the screen — and [ActivitySubmitOrFeedback]
/// renders the pinned [ActivityCheckBar] and then the
/// [ActivityFeedbackPanel], whose Continue calls [onContinue].
///
/// The other hosts (answer review, quick practice) render activities in
/// their own scrolling list and never provide this scope, so they keep the
/// inline Check button and [ActivityFeedbackBanner]. See
/// docs/ARCHITECTURE.md.
class ActivityFrameScope extends InheritedWidget {
  const ActivityFrameScope({
    required this.onContinue,
    this.header,
    this.usefulPhrases = const [],
    this.testMode = false,
    required super.child,
    super.key,
  });

  /// Moves on from the current activity once its feedback is shown.
  final VoidCallback onContinue;

  /// Shown above the prompt — the lesson player's phase · skill line.
  final Widget? header;

  /// The lesson's own phrases (chunk-registry text, `{slot}`s and all),
  /// offered as optional, hidden-until-asked help on production
  /// questions — see `SpeakActivityView`.
  final List<String> usefulPhrases;

  /// A test that must not give answers away (the placement test and the
  /// final assessment): after Check the answer is saved but not marked —
  /// the learner's pick stays shown as selected, the panel says "Answer
  /// saved" with no right answer, no right/wrong sound plays — and
  /// listening questions offer no transcript. See [marksAnswers].
  final bool testMode;

  static ActivityFrameScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivityFrameScope>();

  @override
  bool updateShouldNotify(ActivityFrameScope oldWidget) =>
      onContinue != oldWidget.onContinue ||
      header != oldWidget.header ||
      testMode != oldWidget.testMode ||
      !listEquals(usefulPhrases, oldWidget.usefulPhrases);
}

/// Whether this activity may mark answers right or wrong once checked —
/// false only inside an [ActivityFrameScope] in [ActivityFrameScope.testMode].
bool marksAnswers(BuildContext context) =>
    !(ActivityFrameScope.maybeOf(context)?.testMode ?? false);

/// The shared shell every activity view renders inside: prompt, an optional
/// help area, the type-specific interaction body, and the submit/feedback
/// slot — consistent across all 9 activity types. See
/// docs/ARCHITECTURE.md's lesson-player requirements.
///
/// [prompt] (English) and [promptAr] (Arabic) are rendered as two separate
/// `Text` widgets, each given its own explicit `textDirection` — this is
/// deliberate: it avoids ever concatenating the two languages into one
/// string, which is what "preserve English punctuation and text direction
/// inside Arabic screens" is actually protecting against. Both start at the
/// layout's start edge, so the pair reads as one block in either interface
/// language. Within [promptAr] itself, an embedded Latin word/phrase (e.g.
/// quoting an English term) is handled correctly by Flutter's built-in
/// Unicode Bidi Algorithm support — no manual span-splitting needed.
///
/// Inside an [ActivityFrameScope] the question scrolls and [feedback] is
/// pinned below it; elsewhere everything flows inline in one column.
class ActivityChrome extends StatelessWidget {
  const ActivityChrome({
    required this.prompt,
    this.promptAr,
    this.source,
    this.help,
    required this.body,
    this.feedback,
    super.key,
  });

  final String prompt;
  final String? promptAr;

  /// The text the question is about ([ActivitySourceCard]) — a reading
  /// question's passage, a mediation task's notice. Null for none.
  final String? source;
  final Widget? help;
  final Widget body;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final frame = ActivityFrameScope.maybeOf(context);
    final framed = frame != null;

    final question = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (frame?.header != null) ...[
          frame!.header!,
          const SizedBox(height: AppSpace.xs),
        ],
        ContentText.en(
          prompt,
          style:
              (framed
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: tokens.textPrimary),
        ),
        if (promptAr != null) ...[
          const SizedBox(height: AppSpace.xxs),
          ContentText.ar(
            promptAr!,
            style:
                (framed
                        ? theme.textTheme.bodyLarge
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(color: tokens.textSecondary),
          ),
        ],
        if (source != null) ...[
          const SizedBox(height: AppSpace.sm),
          ActivitySourceCard(text: source!),
        ],
        if (help != null) ...[const SizedBox(height: AppSpace.sm), help!],
        SizedBox(height: framed ? AppSpace.lg : AppSpace.md),
        body,
        if (!framed && feedback != null) ...[
          const SizedBox(height: AppSpace.md),
          feedback!,
        ],
      ],
    );

    if (!framed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: question,
      );
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            child: question,
          ),
        ),
        ?feedback,
      ],
    );
  }
}

/// The inline correct/incorrect/saved-for-review banner used outside the
/// lesson player — never colour alone, per docs/DESIGN_SYSTEM.md: every
/// state pairs a colour role with an icon and text.
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
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Icon(icon, color: onColor),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(label, style: TextStyle(color: onColor)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The [ActivityChrome.feedback] slot's standard content, shared by every
/// activity view so the submit → feedback transition is the same
/// everywhere, per docs/ARCHITECTURE.md.
///
/// Inside an [ActivityFrameScope] (the lesson player): the pinned
/// [ActivityCheckBar] before submission, then the [ActivityFeedbackPanel]
/// sliding up in its place. Elsewhere: an inline Check button, then the
/// [ActivityFeedbackBanner].
class ActivitySubmitOrFeedback extends StatelessWidget {
  const ActivitySubmitOrFeedback({
    required this.submission,
    required this.canSubmit,
    required this.onSubmit,
    this.correctAnswerLabel,
    this.secondaryAction,
    super.key,
  });

  /// Null before the learner has submitted an answer.
  final ActivitySubmission? submission;

  /// Whether Check is currently enabled (e.g. an option is selected, or a
  /// text field is non-empty).
  final bool canSubmit;
  final VoidCallback onSubmit;
  final String? correctAnswerLabel;

  /// An optional quieter action under Check before submission — e.g. a
  /// speaking question's "Type my answer instead".
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final submission = this.submission;
    final frame = ActivityFrameScope.maybeOf(context);

    if (frame != null) {
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      return AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        // Only the incoming child is laid out: the Check bar leaves at
        // once and the panel slides up into its place.
        layoutBuilder: (current, previous) => current ?? const SizedBox(),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: submission == null
            ? ActivityCheckBar(
                key: const ValueKey('check'),
                canSubmit: canSubmit,
                onSubmit: onSubmit,
                secondaryAction: secondaryAction,
              )
            : ActivityFeedbackPanel(
                key: const ValueKey('feedback'),
                submission: submission,
                correctAnswerLabel: correctAnswerLabel,
                onContinue: frame.onContinue,
                testMode: frame.testMode,
              ),
      );
    }

    if (submission != null) {
      return ActivityFeedbackBanner(
        submission: submission,
        correctAnswerLabel: correctAnswerLabel,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: canSubmit ? onSubmit : null,
          child: Text(AppLocalizations.of(context)!.activitySubmitButton),
        ),
        if (secondaryAction != null) ...[
          const SizedBox(height: AppSpace.xxs),
          secondaryAction!,
        ],
      ],
    );
  }
}
