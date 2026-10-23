import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

/// What a screen shows when something it needs failed to load: a plain,
/// bilingual explanation instead of the raw exception, which is an English
/// Dart string that tells a learner nothing. [error] is logged for
/// developers (silent in release builds) and never shown.
///
/// For a curriculum bundle that fails to load, prefer `ContentLoadError`,
/// which can also offer the way back to the learner's own level.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({this.error, this.stackTrace, super.key});

  final Object? error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      developer.log(
        'screen could not load',
        name: 'mohingo.ui',
        error: error,
        stackTrace: stackTrace,
      );
    }
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.errorGenericTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.errorGenericBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
