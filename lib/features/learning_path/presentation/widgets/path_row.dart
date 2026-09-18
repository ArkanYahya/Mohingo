import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';

/// What a node on the learning path shows.
enum PathNodeKind {
  /// Finished: a green circle with a check.
  done,

  /// Where the learner is: an ink ring around the number.
  current,

  /// Not reached yet: a hairline ring around the number.
  upcoming,

  /// A milestone at the end of a stretch (missions, the level's finish): a
  /// solid ink circle with a flag.
  flag,
}

/// The 40dp circle on the path's rail. Shape and content always differ by
/// [kind] (check, number, flag) — never colour alone. [semanticsLabel]
/// replaces the circle's visual content for screen readers.
class PathNode extends StatelessWidget {
  const PathNode({
    required this.kind,
    this.number,
    required this.semanticsLabel,
    super.key,
  });

  final PathNodeKind kind;
  final int? number;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;

    final (
      Color fill,
      Color outline,
      double outlineWidth,
      Color foreground,
    ) = switch (kind) {
      PathNodeKind.done => (
        feedback.success,
        feedback.success,
        2.0,
        feedback.onSuccess,
      ),
      PathNodeKind.current => (
        tokens.card,
        tokens.primaryInk,
        3.0,
        tokens.primaryInk,
      ),
      PathNodeKind.upcoming => (
        tokens.card,
        tokens.border,
        2.0,
        tokens.textSecondary,
      ),
      PathNodeKind.flag => (
        tokens.primaryInk,
        tokens.primaryInk,
        2.0,
        tokens.onPrimaryInk,
      ),
    };

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: outline, width: outlineWidth),
          ),
          child: switch (kind) {
            PathNodeKind.done => Icon(
              Icons.check_rounded,
              size: 22,
              color: foreground,
            ),
            PathNodeKind.flag => Icon(
              Icons.flag_rounded,
              size: 22,
              color: foreground,
            ),
            _ => Text(
              '${number ?? ''}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// One stop on the learning path: a [node] on a continuous vertical rail at
/// the start edge, with [child] beside it. The rail runs through every row
/// and stops at the first and last nodes. Tapping the row calls [onTap]
/// (leave it null when [child] handles its own taps).
class PathRow extends StatelessWidget {
  const PathRow({
    required this.node,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    super.key,
  });

  final Widget node;
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  static const double _nodeTop = AppSpace.sm;
  static const double _nodeCentre = _nodeTop + 20;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: CustomPaint(
              painter: _RailPainter(
                color: tokens.border,
                from: isFirst ? _nodeCentre : 0,
                toEnd: !isLast,
                stopAt: _nodeCentre,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: _nodeTop),
                  child: node,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpace.sm,
                bottom: AppSpace.md,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: row,
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.color,
    required this.from,
    required this.toEnd,
    required this.stopAt,
  });

  final Color color;
  final double from;
  final bool toEnd;
  final double stopAt;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final bottom = toEnd ? size.height : stopAt;
    if (bottom <= from) return;
    canvas.drawLine(
      Offset(x, from),
      Offset(x, bottom),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      color != old.color ||
      from != old.from ||
      toEnd != old.toEnd ||
      stopAt != old.stopAt;
}
