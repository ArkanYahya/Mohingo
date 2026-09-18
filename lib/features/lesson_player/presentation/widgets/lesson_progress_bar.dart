import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';

/// The lesson player's progress: one segment per activity, grouped into
/// the lesson's phases with a wider gap between groups.
///
/// Finished activities are solid ink, the current one a lighter ink, the
/// rest the neutral track. Screen readers hear "3 of 5" — the visual bar
/// replaces the old counter title, not its information. Segments fill
/// from the layout's start edge, so the bar runs right-to-left in Arabic.
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    required this.groupSizes,
    required this.completed,
    super.key,
  });

  /// Activities per phase, in order — see `phaseGroupSizes`.
  final List<int> groupSizes;

  /// Activities finished so far; the one after them is current.
  final int completed;

  int get _total => groupSizes.fold(0, (sum, size) => sum + size);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final total = _total;
    final current = completed.clamp(0, total - 1);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // A step darker than a hairline, so the segments still to come are
    // countable against the page.
    final track = Color.lerp(tokens.border, tokens.textSecondary, 0.15)!;

    Widget segment(int index) {
      final color = index < completed
          ? tokens.primaryInk
          : index == current
          ? tokens.primaryInk.withValues(alpha: 0.38)
          : track;
      return Expanded(
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 250),
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    var index = 0;
    final groups = <Widget>[];
    for (final size in groupSizes) {
      final first = index;
      groups.add(
        Expanded(
          flex: size,
          child: Row(
            children: [
              for (var i = first; i < first + size; i++) ...[
                if (i > first) const SizedBox(width: AppSpace.xxs),
                segment(i),
              ],
            ],
          ),
        ),
      );
      index += size;
    }

    return Semantics(
      label: l10n.lessonPlayerProgress(current + 1, total),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var g = 0; g < groups.length; g++) ...[
              if (g > 0) const SizedBox(width: AppSpace.sm - 2),
              groups[g],
            ],
          ],
        ),
      ),
    );
  }
}
