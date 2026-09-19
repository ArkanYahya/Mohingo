import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../../core/widgets/hairline_card.dart';
import '../../../lesson_player/presentation/widgets/lesson_intro_chrome.dart';

/// The end of a test — the same shape for the placement test, the final
/// mission and the final assessment: a close button, an overline, the
/// outcome as a headline with a line of explanation, then [children] (a
/// recommended unit, the per-skill results), and the next step pinned to
/// the bottom with an optional quieter [secondaryLabel] under it.
class TestResultView extends StatelessWidget {
  const TestResultView({
    required this.overline,
    required this.title,
    required this.body,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryArrow = true,
    super.key,
  });

  final String overline;
  final String title;
  final String body;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// False when the primary action closes rather than goes on.
  final bool primaryArrow;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xxs),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  0,
                  AppSpace.md,
                  AppSpace.lg,
                ),
                children: [
                  Text(
                    overline.toUpperCase(),
                    style: overlineStyle(context, color: tokens.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
            LessonActionBar(
              label: primaryLabel,
              onPressed: onPrimary,
              showArrow: primaryArrow,
              secondary: secondaryLabel == null
                  ? null
                  : TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One skill's result: its icon and name, a status pill (or score), and
/// optionally a bar and a caption.
class SkillResultRow extends StatelessWidget {
  const SkillResultRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.progress,
    this.progressDone = false,
    this.caption,
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  /// 0–1, drawn as a 6px bar; null for none.
  final double? progress;

  /// Draws the bar in the success colour.
  final bool progressDone;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final success = theme.extension<FeedbackTheme>()!.success;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md - 2,
          vertical: AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: 20, color: tokens.textSecondary),
                ),
                const SizedBox(width: AppSpace.sm - 2),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                trailing,
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: progressDone ? success : tokens.primaryInk,
                  backgroundColor: Color.lerp(
                    tokens.border,
                    tokens.textSecondary,
                    0.15,
                  ),
                ),
              ),
            ],
            if (caption != null) ...[
              const SizedBox(height: AppSpace.xxs),
              Text(
                caption!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [rows] in one hairline card, separated by dividers.
class ResultRowsCard extends StatelessWidget {
  const ResultRowsCard({required this.rows, super.key});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return HairlineCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            row,
          ],
        ],
      ),
    );
  }
}
