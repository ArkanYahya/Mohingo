import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A quiet `card` surface with a 1px `border` outline and the card radius —
/// the default container for secondary content (examples, status lines,
/// "where you met it").
class HairlineCard extends StatelessWidget {
  const HairlineCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md - 2),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
