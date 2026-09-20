import 'package:flutter/material.dart';

import '../../../../content/catalog/level_catalog.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../progress/domain/level_access.dart';

/// Every CEFR level in the catalogue as a pill: the one on screen filled,
/// an open level outlined and tappable, a locked one outlined behind a
/// small lock, and the levels with no content yet outlined and inert.
///
/// A locked level is still tappable — the tap is what opens the
/// explanation and the way forward. Progression here is a recommendation,
/// never a wall; see docs/PRODUCT.md flow 5.
class LevelStrip extends StatelessWidget {
  const LevelStrip({
    required this.catalog,
    required this.shownLevelId,
    required this.access,
    required this.onSelect,
    super.key,
  });

  final List<LevelCatalogEntry> catalog;

  /// The level whose course page is on screen.
  final String shownLevelId;

  /// Each level's access by level id; a level missing from the map is
  /// treated as [LevelAccess.noContent].
  final Map<String, LevelAccess> access;

  final void Function(LevelCatalogEntry entry, LevelAccess access) onSelect;

  LevelAccess _accessFor(LevelCatalogEntry entry) =>
      access[entry.levelId] ?? LevelAccess.noContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final shownCode = catalog
        .firstWhere(
          (e) => e.levelId == shownLevelId,
          orElse: () => catalog.first,
        )
        .cefrCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.learnLevelStripTitle.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final entry in catalog)
              _LevelPill(
                entry: entry,
                access: _accessFor(entry),
                isShown: entry.levelId == shownLevelId,
                onTap: () => onSelect(entry, _accessFor(entry)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.learnLevelComingLaterBody(shownCode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.entry,
    required this.access,
    required this.isShown,
    required this.onTap,
  });

  final LevelCatalogEntry entry;
  final LevelAccess access;
  final bool isShown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final code = entry.cefrCode;
    final tappable = access != LevelAccess.noContent;
    final locked =
        access == LevelAccess.lockedNeedsPrerequisite ||
        access == LevelAccess.notReleased;
    final foreground = isShown ? tokens.onPrimaryInk : tokens.textSecondary;

    final label = isShown
        ? l10n.learnLevelSemanticsCurrent(code)
        : switch (access) {
            LevelAccess.open => l10n.learnLevelSemanticsOpen(code),
            LevelAccess.lockedNeedsPrerequisite ||
            LevelAccess.notReleased => l10n.learnLevelSemanticsLocked(code),
            LevelAccess.noContent => l10n.learnLevelSemanticsComingSoon(code),
          };

    return Semantics(
      // Explicit so a coming-later pill (not a button — nothing else here
      // marks it as a boundary) still gets its own node instead of
      // silently merging its label into the strip's title/caption text.
      container: true,
      button: tappable,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isShown ? tokens.primaryInk : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: isShown
                ? BorderSide.none
                : BorderSide(
                    color:
                        Color.lerp(tokens.border, tokens.textSecondary, 0.2) ??
                        tokens.border,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tappable ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (locked && !isShown) ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: foreground,
                      ),
                      const SizedBox(width: AppSpace.xs - 2),
                    ],
                    Text(
                      code,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
