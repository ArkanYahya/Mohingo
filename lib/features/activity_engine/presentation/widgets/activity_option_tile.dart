import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';
import 'answer_tile_state.dart';

/// One answer of a single-choice question: a full-width card row with a
/// radio mark, 56dp tall so it's an easy target.
///
/// After Check the radio gives way to a check or cross, so the result
/// never relies on colour alone. [label] is English content and always
/// reads left-to-right, starting at the layout's start edge.
class ActivityOptionTile extends StatelessWidget {
  const ActivityOptionTile({
    required this.label,
    required this.state,
    this.onTap,
    super.key,
  });

  final String label;
  final AnswerTileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = answerTileColors(context, state);
    final leading = switch (state) {
      AnswerTileState.correct => Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: theme.extension<FeedbackTheme>()!.success,
      ),
      AnswerTileState.incorrect => Icon(
        Icons.cancel_rounded,
        size: 22,
        color: theme.colorScheme.error,
      ),
      _ => _RadioMark(selected: state == AnswerTileState.selected),
    };

    final tile = Material(
      color: colors.fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: colors.outline, width: colors.outlineWidth),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: Row(
              children: [
                SizedBox(width: 22, child: Center(child: leading)),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      label,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      selected: state == AnswerTileState.selected,
      inMutuallyExclusiveGroup: true,
      child: state == AnswerTileState.dimmed
          ? Opacity(opacity: 0.5, child: tile)
          : tile,
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.extension<AppTokens>()!.primaryInk;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? ink : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
