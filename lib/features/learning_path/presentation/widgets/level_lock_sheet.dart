import 'package:flutter/material.dart';

import '../../../../content/catalog/level_catalog.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../progress/domain/level_access.dart';

/// Why a level isn't open, and what the learner can do about it.
///
/// Two shapes. A level they haven't reached yet offers the placement test
/// or opening it anyway — the app recommends an order, it doesn't enforce
/// one (docs/PRODUCT.md flow 5). A level the app hasn't released yet offers
/// only to look at what it covers, because there is nothing to open.
Future<void> showLevelLockSheet(
  BuildContext context, {
  required LevelCatalogEntry entry,
  required String prerequisiteCode,
  required LevelAccess access,
  required VoidCallback onTakePlacementTest,
  required VoidCallback onOpenAnyway,
  required VoidCallback onBrowse,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final tokens = theme.extension<AppTokens>()!;
      final l10n = AppLocalizations.of(sheetContext)!;
      final code = entry.cefrCode;
      final notReleased = access == LevelAccess.notReleased;

      void closeThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      // Two level codes in one Arabic sentence read in the wrong order
      // without isolates ("A2 builds on A1" rendered as "A1 … A2"). This
      // repo wraps the substituted value at the call site rather than in
      // the ARB, where the raw characters trip text_direction_code_point
      // in gen-l10n's output — see course_screen.dart's homeJourneyNext.
      final isolatedCode = '\u2068$code\u2069';
      final isolatedPrerequisite = '\u2068$prerequisiteCode\u2069';

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          0,
          AppSpace.md,
          AppSpace.md + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              notReleased
                  ? l10n.levelNotReleasedTitle(code)
                  : l10n.levelLockTitle(isolatedCode, isolatedPrerequisite),
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              notReleased
                  ? l10n.levelNotReleasedBody
                  : l10n.levelLockBody(isolatedPrerequisite, isolatedCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            if (notReleased)
              FilledButton(
                onPressed: () => closeThen(onBrowse),
                child: Text(l10n.levelNotReleasedBrowse(code)),
              )
            else ...[
              FilledButton(
                onPressed: () => closeThen(onTakePlacementTest),
                child: Text(l10n.levelLockTakeTest),
              ),
              const SizedBox(height: AppSpace.xxs),
              TextButton(
                onPressed: () => closeThen(onOpenAnyway),
                child: Text(l10n.levelLockOpenAnyway(code)),
              ),
            ],
          ],
        ),
      );
    },
  );
}
