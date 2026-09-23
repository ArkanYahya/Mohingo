import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../../core/widgets/content_text.dart';
import '../../../../core/widgets/hairline_card.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../lesson_player/presentation/widgets/lesson_intro_chrome.dart';

/// One line of a test intro's list: a section of the test or a stage of
/// the mission, led by an [icon] or a stage [number].
class TestIntroRow {
  const TestIntroRow({
    required this.title,
    this.icon,
    this.number,
    this.titleAr,
    this.trailing,
  });

  final IconData? icon;
  final int? number;
  final String title;
  final String? titleAr;
  final String? trailing;
}

/// The screen before a test starts — the same shape for the placement
/// test, the final mission and the final assessment: a close button; an
/// overline, the title (and its Arabic), what it is, and its size and
/// time; a list of what it covers; an optional rules note; and the start
/// button pinned to the bottom.
class TestIntroView extends StatelessWidget {
  const TestIntroView({
    required this.overline,
    required this.title,
    required this.lead,
    required this.heading,
    required this.rows,
    required this.startLabel,
    required this.starting,
    required this.onStart,
    this.titleAr,
    this.meta,
    this.note,
    super.key,
  });

  final String overline;
  final String title;

  /// The title's Arabic, when the title is English content.
  final String? titleAr;
  final String lead;
  final String? meta;
  final String heading;
  final List<TestIntroRow> rows;

  /// How the test works, e.g. that answers aren't marked as you go.
  final String? note;
  final String startLabel;

  /// True while the attempt is being created — Start does nothing.
  final bool starting;
  final VoidCallback onStart;

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
                  if (titleAr == null)
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    )
                  else
                    ContentText.en(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  if (titleAr != null)
                    ContentText.ar(
                      titleAr!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    lead,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      meta!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                  SectionHeading(heading),
                  HairlineCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, row) in rows.indexed) ...[
                          if (i > 0) Divider(height: 1, color: tokens.border),
                          _IntroRowTile(row: row),
                        ],
                      ],
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: AppSpace.md),
                    HairlineCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.visibility_off_outlined,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              note!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            LessonActionBar(
              label: startLabel,
              onPressed: () {
                if (!starting) onStart();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroRowTile extends StatelessWidget {
  const _IntroRowTile({required this.row});

  final TestIntroRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final number = row.number;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md - 2,
          vertical: AppSpace.sm - 2,
        ),
        child: Row(
          children: [
            if (number != null)
              CircleAvatar(
                radius: 14,
                backgroundColor: tokens.primaryInkTint,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.primaryInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (row.icon != null)
              ExcludeSemantics(
                child: Icon(row.icon, size: 20, color: tokens.textSecondary),
              ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (row.titleAr == null)
                    Text(
                      row.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    )
                  else
                    ContentText.en(
                      row.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  if (row.titleAr != null)
                    ContentText.ar(
                      row.titleAr!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (row.trailing != null) ...[
              const SizedBox(width: AppSpace.xs),
              Text(
                row.trailing!,
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
