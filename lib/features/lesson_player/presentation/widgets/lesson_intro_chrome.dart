import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';

/// The top of a lesson-intro screen: "UNIT 2 · LESSON 1", then the title
/// (English content reads left-to-right) and, when given, its Arabic line —
/// both starting at the layout's start edge.
class LessonIntroHeader extends StatelessWidget {
  const LessonIntroHeader({
    required this.overline,
    required this.title,
    this.titleAr,
    this.titleIsContent = true,
    super.key,
  });

  final String overline;
  final String title;
  final String? titleAr;

  /// True for a lesson title (English content, always LTR); false for UI
  /// copy in the interface language.
  final bool titleIsContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          title,
          textDirection: titleIsContent ? TextDirection.ltr : null,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        if (titleAr != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            titleAr!,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// The bottom bar of the lesson intro and lesson-complete screens: one
/// full-width button with a forward arrow, pinned like the question
/// frame's Check bar, and an optional quieter [secondary] action under it.
class LessonActionBar extends StatelessWidget {
  const LessonActionBar({
    required this.label,
    required this.onPressed,
    this.secondary,
    this.showArrow = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? secondary;

  /// False for a button that goes back rather than on ("Back to unit").
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
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
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label)),
                  if (showArrow) ...[
                    const SizedBox(width: AppSpace.xs),
                    // arrow_forward mirrors itself in right-to-left layouts.
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: AppSpace.xxs),
              secondary!,
            ],
          ],
        ),
      ),
    );
  }
}
