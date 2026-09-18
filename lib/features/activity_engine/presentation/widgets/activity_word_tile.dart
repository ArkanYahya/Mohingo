import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import 'answer_tile_state.dart';

/// A tappable word or short phrase — gap options, the build-the-sentence
/// word bank, and matching items.
///
/// Drawn as a key: a card with a firmer bottom edge, so it reads as
/// something to press. [label] is English content and always reads
/// left-to-right. A [badge] number marks which items belong together in a
/// matching question.
///
/// By default the tile is one line at [heightOf] — word banks line up on
/// it. With [expand] it fills its parent's width and may wrap, for
/// matching columns where an item can be a short phrase.
class ActivityWordTile extends StatelessWidget {
  const ActivityWordTile({
    required this.label,
    this.state = AnswerTileState.idle,
    this.onTap,
    this.badge,
    this.expand = false,
    super.key,
  });

  final String label;
  final AnswerTileState state;
  final VoidCallback? onTap;
  final int? badge;
  final bool expand;

  static const double _edge = 3;

  /// The one-line tile height at the current text scale.
  static double heightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) * 1.45 +
      2 * AppSpace.sm +
      _edge;

  static TextStyle _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!
          .copyWith(fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colors = answerTileColors(context, state);
    final edge =
        state == AnswerTileState.idle || state == AnswerTileState.dimmed
        ? Color.lerp(tokens.border, tokens.textSecondary, 0.2)!
        : colors.outline;

    final text = Text(
      label,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: expand ? null : 1,
      overflow: expand ? null : TextOverflow.ellipsis,
      style: _labelStyle(context).copyWith(color: colors.foreground),
    );
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (badge != null) ...[
          _PairBadge(number: badge!),
          const SizedBox(width: AppSpace.xs),
        ],
        Flexible(child: text),
      ],
    );

    Widget tile = DecoratedBox(
      decoration: BoxDecoration(
        color: edge,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: _edge),
        child: Material(
          color: colors.fill,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            side: BorderSide(color: colors.outline, width: colors.outlineWidth),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: expand
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32),
                      child: Center(child: content),
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
    if (!expand) {
      tile = SizedBox(height: heightOf(context), child: tile);
    }

    return Semantics(
      button: onTap != null,
      selected: state == AnswerTileState.selected,
      child: state == AnswerTileState.dimmed
          ? Opacity(opacity: 0.5, child: tile)
          : tile,
    );
  }
}

/// The empty slot a word leaves in the word bank once it's been used, the
/// same size as the tile, so the bank never jumps around while the learner
/// builds a sentence. Measured rather than rendering the word invisibly,
/// so the used word isn't still in the tree for tests or screen readers.
class ActivityWordTileGhost extends StatelessWidget {
  const ActivityWordTileGhost({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final painter = TextPainter(
      text: TextSpan(text: label, style: ActivityWordTile._labelStyle(context)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width + 2 * AppSpace.md;
    painter.dispose();
    return ExcludeSemantics(
      child: Container(
        width: math.min(width, MediaQuery.sizeOf(context).width),
        height: ActivityWordTile.heightOf(context),
        decoration: BoxDecoration(
          color: tokens.cardMuted,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    );
  }
}

class _PairBadge extends StatelessWidget {
  const _PairBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.primaryInk,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: theme.textTheme.labelMedium?.copyWith(
          color: tokens.onPrimaryInk,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
