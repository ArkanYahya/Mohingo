import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_tokens.dart';

/// Home's one primary action: resume the lesson the learner should be on.
///
/// The only elevated surface on the page. A lightly brand-tinted identity
/// band (lesson badge, position, English title, Arabic support) sits over
/// a neutral action area (meta, lesson progress, full-width CTA), so the
/// card reads as a *lesson*, not a slab of colour. Every content field is
/// optional so the same card serves all three hero states — resume a
/// lesson, review a finished-but-unmastered unit, and level complete.
class ContinueLessonCard extends StatelessWidget {
  const ContinueLessonCard({
    required this.badge,
    required this.overline,
    required this.title,
    required this.ctaLabel,
    required this.onPressed,
    this.titleAr,
    this.meta,
    this.body,
    this.progress,
    this.progressLabel,
    this.progressValueLabel,
    super.key,
  });

  /// Shown in the leading badge — the lesson number, or an icon.
  final Widget badge;
  final String overline;

  /// English title, always laid out left-to-right.
  final String title;

  /// Arabic support line, always laid out right-to-left.
  final String? titleAr;

  /// Supporting facts, e.g. "Guided lesson · 4 activities".
  final String? meta;

  /// A short explanatory sentence, used when there's no progress to show.
  final String? body;

  /// 0-1; `null` hides the progress row entirely.
  final double? progress;
  final String? progressLabel;
  final String? progressValueLabel;

  final String ctaLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final tokens = theme.extension<AppTokens>()!;
    final isDark = theme.brightness == Brightness.dark;
    final band = Color.alphaBlend(
      tokens.primaryInk.withValues(alpha: isDark ? 0.14 : 0.07),
      tokens.card,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: isDark ? Border.all(color: tokens.border) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: tokens.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: tokens.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: band,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge(child: badge),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overline.toUpperCase(),
                            style: text.labelSmall?.copyWith(
                              color: tokens.primaryInk,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            title,
                            textDirection: TextDirection.ltr,
                            style: text.titleLarge?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                          if (titleAr != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              titleAr!,
                              textDirection: TextDirection.rtl,
                              style: text.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (meta != null)
                    Text(
                      meta!,
                      style: text.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  if (body != null)
                    Text(
                      body!,
                      style: text.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  if (progress != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    _LessonProgress(
                      value: progress!,
                      label: progressLabel ?? '',
                      valueLabel: progressValueLabel ?? '',
                    ),
                  ],
                  const SizedBox(height: AppSpace.md),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onPressed();
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(ctaLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final onInk = theme.brightness == Brightness.dark
        ? tokens.page
        : Colors.white;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tokens.primaryInk,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      alignment: Alignment.center,
      child: IconTheme(
        data: IconThemeData(color: onInk, size: 24),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.titleLarge!.copyWith(color: onInk),
          child: child,
        ),
      ),
    );
  }
}

/// Label, value and a bar that animates to its value on appear — skipped
/// under the OS reduce-motion setting.
class _LessonProgress extends StatelessWidget {
  const _LessonProgress({
    required this.value,
    required this.label,
    required this.valueLabel,
  });

  final double value;
  final String label;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '$label, $valueLabel',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(color: tokens.textSecondary),
                ),
              ),
              Text(
                valueLabel,
                style: text.labelMedium?.copyWith(color: tokens.primaryInk),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: animated,
                minHeight: 6,
                color: tokens.primaryInk,
                backgroundColor: tokens.cardMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
