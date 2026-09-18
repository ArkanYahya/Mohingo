import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/overline_style.dart';

/// An uppercase overline starting a section of a detail page ("EXAMPLES",
/// "WHERE YOU MET IT"), with the page's section spacing around it.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xs),
      child: Text(
        text.toUpperCase(),
        style: overlineStyle(context, color: tokens.textSecondary),
      ),
    );
  }
}
