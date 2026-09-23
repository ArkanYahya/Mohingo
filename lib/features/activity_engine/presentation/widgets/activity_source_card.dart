import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/content_text.dart';

/// The text a question is about — a message, a notice, a menu, two short
/// profiles — shown between the prompt and the answers. English content,
/// so always left-to-right from the left edge in either interface language
/// ([ContentText]). Shown in test mode too: it is the question's input,
/// not its answer.
class ActivitySourceCard extends StatelessWidget {
  const ActivitySourceCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: ContentText.en(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tokens.textPrimary,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
