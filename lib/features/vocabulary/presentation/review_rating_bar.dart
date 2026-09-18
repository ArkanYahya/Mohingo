import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/local/database.dart';
import '../domain/spaced_review_scheduler.dart';

/// The pinned bottom bar for rating a word or phrase: "How well did you
/// know this?" and Again / Good / Easy, each saying when that answer
/// brings the item back (from the same [SpacedReviewScheduler] that saves
/// it). Used by the review session and the word and phrase pages.
class ReviewRatingBar extends StatelessWidget {
  const ReviewRatingBar({
    required this.state,
    required this.enabled,
    required this.onRate,
    super.key,
  });

  /// The item's review row; null when it isn't in review yet.
  final VocabularyReviewStateData? state;
  final bool enabled;
  final ValueChanged<ReviewQuality> onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // Side by side normally; stacked full-width rows when the screen is
    // narrow for the text size, so a hint like "tomorrow" never breaks.
    final stacked =
        MediaQuery.sizeOf(context).width /
            MediaQuery.textScalerOf(context).scale(1) <
        340;

    Widget button(ReviewQuality quality, String label, {Color? color}) {
      final days = SpacedReviewScheduler.schedule(
        currentEaseFactor: state?.easeFactor ?? 2.5,
        currentIntervalDays: state?.intervalDays ?? 0,
        currentRepetitions: state?.repetitions ?? 0,
        quality: quality,
        now: now,
      ).intervalDays;
      final hint = Text(
        l10n.reviewSeeAgain(days),
        style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      );
      final outlined = OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
          foregroundColor: color ?? tokens.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
        onPressed: enabled ? () => onRate(quality) : null,
        child: stacked
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    const SizedBox(width: AppSpace.xs),
                    hint,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(label), hint],
              ),
      );
      return stacked ? outlined : Expanded(child: outlined);
    }

    final buttons = [
      button(
        ReviewQuality.again,
        l10n.reviewQualityAgain,
        color: theme.colorScheme.error,
      ),
      button(ReviewQuality.good, l10n.reviewQualityGood),
      button(ReviewQuality.easy, l10n.reviewQualityEasy),
    ];

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
            Text(
              l10n.reviewHowWellKnew,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            if (stacked)
              for (final (i, b) in buttons.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.xs),
                b,
              ]
            else
              Row(
                children: [
                  for (final (i, b) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.xs),
                    b,
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
