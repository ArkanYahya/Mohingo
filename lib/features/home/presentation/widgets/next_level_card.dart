import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';

/// Home's offer of the next level, shown only once the learner has mastered
/// every unit of the level they are in and the level after it is released.
///
/// Deliberately a flat card the learner taps, not a second filled button
/// competing with the hero's CTA and not an automatic switch: moving level
/// is the learner's decision, and the whole lock design rests on that (see
/// docs/superpowers/specs/2026-09-19-a2-level-design.md, Design 3).
class NextLevelCard extends StatelessWidget {
  const NextLevelCard({
    required this.currentLevelCode,
    required this.nextLevelCode,
    required this.onStart,
    super.key,
  });

  /// The level the learner has just finished, e.g. `"A1"`.
  final String currentLevelCode;

  /// The level being offered, e.g. `"A2"`.
  final String nextLevelCode;

  /// Makes [nextLevelCode] the level the learner is working in.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.primaryInk),
      ),
      child: InkWell(
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: tokens.primaryInkTint,
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 20,
                    color: tokens.primaryInk,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeNextLevelOverline.toUpperCase(),
                      style: overlineStyle(context, color: tokens.primaryInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeNextLevelTitle(nextLevelCode),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeNextLevelBody(currentLevelCode, nextLevelCode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              // chevron_right mirrors itself in right-to-left layouts.
              Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
