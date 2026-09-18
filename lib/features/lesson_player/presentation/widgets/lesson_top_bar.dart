import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';

/// The lesson player's slim top bar: a close button at the start edge and
/// the progress bar filling the rest. No title — the question itself is
/// the headline.
class LessonTopBar extends StatelessWidget {
  const LessonTopBar({
    required this.onClose,
    required this.progress,
    super.key,
  });

  final VoidCallback onClose;
  final Widget progress;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpace.xxs,
          end: AppSpace.lg,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              tooltip: AppLocalizations.of(context)!.lessonPlayerClose,
              icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
            ),
            const SizedBox(width: AppSpace.xxs),
            Expanded(child: progress),
          ],
        ),
      ),
    );
  }
}
