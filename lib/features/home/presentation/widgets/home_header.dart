import 'package:flutter/material.dart';

import '../../../../core/l10n/cefr_descriptor_label.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/gamification_theme_extension.dart';
import '../../domain/day_part.dart';

/// Home's top area: a time-of-day greeting with the learner's name, then
/// two small supporting pills — current level and streak. Replaces the old
/// "Home" app-bar title and the full-width streak card: the streak is a
/// motivator, not the first thing to read. With no saved name the greeting
/// itself becomes the headline.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.dayPart,
    required this.name,
    required this.levelCode,
    required this.streakDays,
    this.badgesKey,
    super.key,
  });

  final DayPart dayPart;
  final String? name;

  /// The CEFR code of the level the learner is in — the pill names this one,
  /// never a fixed level.
  final String levelCode;

  final int streakDays;

  /// Attached to the level and streak pills, for the app guide to point at.
  final Key? badgesKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final greeting = switch (dayPart) {
      DayPart.morning => l10n.homeGreetingMorning,
      DayPart.afternoon => l10n.homeGreetingAfternoon,
      DayPart.evening => l10n.homeGreetingEvening,
    };
    final name = this.name;
    // A level with no descriptor yet shows its bare code rather than
    // borrowing another level's — "A2 · Beginner" would undo what
    // finishing A1 meant.
    final descriptor = cefrDescriptorLabel(l10n, levelCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null)
          Text(
            greeting,
            style: text.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
        Semantics(
          header: true,
          child: Text(
            name ?? greeting,
            style: text.headlineSmall?.copyWith(color: tokens.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          key: badgesKey,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Pill(
                  child: Text(
                    descriptor == null
                        ? levelCode
                        : l10n.homeLevelBadge(levelCode, descriptor),
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            _StreakPill(days: streakDays),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.cardMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: 7,
        ),
        child: child,
      ),
    );
  }
}

/// The streak as a supporting metric. An active streak gets the warm
/// [GamificationTheme.streakAccent] flame and a one-time "pop" when it
/// first appears — skipped under the OS reduce-motion setting.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final gamification = Theme.of(context).extension<GamificationTheme>()!;
    final active = days > 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final flame = Icon(
      active
          ? Icons.local_fire_department_rounded
          : Icons.local_fire_department_outlined,
      size: 18,
      color: active ? gamification.streakAccent : tokens.textSecondary,
    );

    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active && !reduceMotion)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: flame,
            )
          else
            flame,
          const SizedBox(width: AppSpace.xxs),
          Text(
            l10n.homeStreakChip(days),
            style: text.labelMedium?.copyWith(color: tokens.textPrimary),
          ),
        ],
      ),
    );
  }
}
