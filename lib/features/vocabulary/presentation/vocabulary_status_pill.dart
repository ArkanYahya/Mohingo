import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../domain/vocabulary_status.dart';

/// A small label for a word's or phrase's review status: amber "Due" with
/// a refresh mark, neutral "Learning", green "Learned" with a check.
/// Nothing for an item not in review yet — most of the list, so it stays
/// quiet.
class VocabularyStatusPill extends StatelessWidget {
  const VocabularyStatusPill({required this.status, super.key});

  final VocabularyStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final streak = theme.extension<GamificationTheme>()!.streakAccent;
    final l10n = AppLocalizations.of(context)!;

    // (icon, icon colour, fill, text colour, label). The amber accent is
    // too light for small text on a pale fill, so Due's text stays
    // textPrimary and only its mark is amber.
    final (IconData?, Color, Color, Color, String)? look = switch (status) {
      VocabularyStatus.newItem => null,
      VocabularyStatus.due => (
        Icons.refresh_rounded,
        streak,
        Color.alphaBlend(streak.withValues(alpha: 0.16), tokens.card),
        tokens.textPrimary,
        l10n.vocabularyStatDue,
      ),
      VocabularyStatus.learning => (
        null,
        tokens.textSecondary,
        tokens.cardMuted,
        tokens.textSecondary,
        l10n.vocabularyStatLearning,
      ),
      VocabularyStatus.learned => (
        Icons.check_rounded,
        feedback.onSuccessContainer,
        feedback.successContainer,
        feedback.onSuccessContainer,
        l10n.vocabularyStateLearned,
      ),
    };
    if (look == null) return const SizedBox.shrink();
    final (icon, iconColor, fill, ink, label) = look;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 3),
          ],
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: ink)),
        ],
      ),
    );
  }
}
