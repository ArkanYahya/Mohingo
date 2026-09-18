import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';

/// Spaced-review status, sized to what it asks of the learner: nothing
/// due is a quiet one-line status, not a card; items due become a card
/// with its own (secondary, tonal) "Review now" action — never a second
/// solid button competing with the lesson CTA.
class ReviewStatus extends StatelessWidget {
  const ReviewStatus({
    required this.dueCount,
    required this.onReview,
    super.key,
  });

  final int dueCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final feedback = Theme.of(context).extension<FeedbackTheme>()!;
    final title = l10n.homeReviewDueTitle(dueCount);

    if (dueCount <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xxs,
          vertical: AppSpace.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: feedback.success,
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                title,
                style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final tint = Color.alphaBlend(
      tokens.primaryInk.withValues(alpha: 0.12),
      tokens.card,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(
              Icons.style_outlined,
              size: 20,
              color: tokens.primaryInk,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title,
              style: text.titleSmall?.copyWith(color: tokens.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          FilledButton.tonal(
            onPressed: onReview,
            style: FilledButton.styleFrom(
              backgroundColor: tint,
              foregroundColor: tokens.primaryInk,
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            ),
            child: Text(l10n.homeReviewNowCta),
          ),
        ],
      ),
    );
  }
}
