import 'package:flutter/material.dart';

/// The overline style — [TextTheme.labelSmall]'s tracked caps — adjusted
/// for the ambient text direction.
///
/// Arabic has no letter case, and letter-spacing pulls its joined letters
/// apart, so in an RTL layout the tracking is dropped and the size goes up
/// a point to keep the same visual weight. Callers still upper-case the
/// string themselves; that is a no-op for Arabic. See docs/DESIGN_SYSTEM.md.
TextStyle overlineStyle(BuildContext context, {Color? color}) {
  final base = Theme.of(context).textTheme.labelSmall!;
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return base.copyWith(
    color: color,
    letterSpacing: isRtl ? 0 : null,
    fontSize: isRtl ? base.fontSize! + 1 : null,
  );
}
