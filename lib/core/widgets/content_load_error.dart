import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

/// What a screen shows when a level's bundle will not load.
///
/// Never the raw exception: it is an English Dart string, and an
/// Arabic-only learner reading it learns nothing and is given nothing to
/// do. This says what happened in their own language and, when the level
/// that failed is one they were only looking at, offers the way back to
/// the level they are actually in.
///
/// Used by the Learn tab and by the two browsable registry lists (words &
/// phrases, grammar), which reach this the same way — a level chip loads a
/// second bundle that can fail on its own.
class ContentLoadError extends StatelessWidget {
  const ContentLoadError({
    required this.currentCode,
    required this.onBack,
    super.key,
  });

  /// The CEFR code of the level to go back to, or null when the level that
  /// failed IS the learner's own — there is nowhere to go back to, and the
  /// app-level gate covers the base level.
  final String? currentCode;

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.contentErrorTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.contentErrorBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (currentCode != null) ...[
              const SizedBox(height: AppSpace.md),
              TextButton(
                onPressed: onBack,
                child: Text(l10n.learnPreviewBackToCurrent(currentCode!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
