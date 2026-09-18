import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';

/// The state of one unit on the level's journey track.
enum JourneyStep { mastered, current, ahead }

/// The level as a journey: one segment per unit (mastered / current /
/// ahead), the learner's position, and what comes next. Replaces the bare
/// "A1 progress — 1 of 13 units mastered" bar. Taps through to the Learn
/// path. The track follows reading direction, so it runs right-to-left in
/// the Arabic interface.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    required this.steps,
    required this.position,
    required this.nowTitle,
    required this.nextTitle,
    required this.onTap,
    super.key,
  });

  final List<JourneyStep> steps;

  /// 1-based index of the current unit; `null` once every unit is mastered.
  final int? position;
  final String nowTitle;
  final String? nextTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final masteredCount = steps.where((s) => s == JourneyStep.mastered).length;

    return Material(
      color: tokens.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.homeJourneyTitle,
                        style: text.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (position != null)
                    Text(
                      l10n.homeJourneyUnitOf(position!, steps.length),
                      style: text.labelMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  const SizedBox(width: AppSpace.xxs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Semantics(
                label: l10n.homeLevelProgressCaption(
                  masteredCount,
                  steps.length,
                ),
                excludeSemantics: true,
                child: _JourneyTrack(steps: steps),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                nowTitle,
                style: text.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nextTitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  nextTitle!,
                  style: text.bodySmall?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyTrack extends StatelessWidget {
  const _JourneyTrack({required this.steps});

  final List<JourneyStep> steps;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final feedback = Theme.of(context).extension<FeedbackTheme>()!;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: steps[i] == JourneyStep.current ? 8 : 6,
              decoration: BoxDecoration(
                color: switch (steps[i]) {
                  JourneyStep.mastered => feedback.success,
                  JourneyStep.current => tokens.primaryInk,
                  JourneyStep.ahead => tokens.cardMuted,
                },
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
