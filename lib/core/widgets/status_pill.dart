import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/feedback_theme_extension.dart';
import '../theme/gamification_theme_extension.dart';

/// How a [StatusPill] reads.
enum StatusTone {
  /// Plain information: `textSecondary` on `cardMuted`.
  neutral,

  /// Done or passed: `onSuccessContainer` on `successContainer`.
  success,

  /// Needs the learner (due, not passed yet): an amber (`streakAccent`)
  /// mark on an amber tint. The text stays `textPrimary` — amber text would
  /// fail contrast at this size.
  attention,
}

/// A small rounded status label with an optional leading mark.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final streak = theme.extension<GamificationTheme>()!.streakAccent;

    final (Color fill, Color ink, Color mark) = switch (tone) {
      StatusTone.neutral => (
        tokens.cardMuted,
        tokens.textSecondary,
        tokens.textSecondary,
      ),
      StatusTone.success => (
        feedback.successContainer,
        feedback.onSuccessContainer,
        feedback.onSuccessContainer,
      ),
      StatusTone.attention => (
        Color.alphaBlend(streak.withValues(alpha: 0.16), tokens.card),
        tokens.textPrimary,
        streak,
      ),
    };

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
            Icon(icon, size: 14, color: mark),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
