import 'package:flutter/material.dart';

import '../../../../content/catalog/level_catalog.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../progress/domain/level_access.dart';

/// The levels that exist, as one segmented track under the course title:
/// the level on screen filled, the others outlined, a locked one behind a
/// small lock. Levels with no content yet are not segments — the caption
/// under the track is what says more levels are coming.
///
/// [currentLevelId] always reflects the level the learner is enrolled in,
/// never what the page happens to be showing. Browsing another level's
/// units does not move the filled segment: browsing is a view, not a move.
///
/// A locked level is still tappable — the tap is what opens the
/// explanation and the way forward. Progression here is a recommendation,
/// never a wall; see docs/PRODUCT.md flow 5.
class LevelStrip extends StatelessWidget {
  const LevelStrip({
    required this.catalog,
    required this.currentLevelId,
    required this.access,
    required this.onSelect,
    super.key,
  });

  final List<LevelCatalogEntry> catalog;

  /// The level the learner is enrolled in.
  final String currentLevelId;

  /// Each level's access by level id.
  final Map<String, LevelAccess> access;

  final void Function(LevelCatalogEntry entry, LevelAccess access) onSelect;

  /// A level whose access hasn't resolved yet must default to the state
  /// with no persistent action behind it, not merely to "some kind of
  /// locked": [LevelAccess.lockedNeedsPrerequisite]'s sheet offers "Open
  /// anyway", and `LevelSelectionController.unlock`/`select` don't
  /// re-check access — a tap landing in that window could move the
  /// learner into a level the app hasn't released. Never open (which
  /// would let a tap switch into it on a guess) and never
  /// [LevelAccess.noContent] (which is the one thing a level in this
  /// track cannot be). The real value replaces it a frame later.
  LevelAccess _accessFor(LevelCatalogEntry entry) =>
      access[entry.levelId] ?? LevelAccess.notReleased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    // Only the levels that have content are switchable. B1-C2 ship as
    // `comingSoon` catalogue entries with no bundle; they would be dead
    // segments, and six of them wrap onto a second row.
    final switchable = [
      for (final entry in catalog)
        if (entry.availability != LevelAvailability.comingSoon) entry,
    ];
    final currentCode = catalog
        .firstWhere(
          (e) => e.levelId == currentLevelId,
          orElse: () => catalog.first,
        )
        .cefrCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.cardMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (final entry in switchable)
                  Expanded(
                    child: _LevelSegment(
                      entry: entry,
                      access: _accessFor(entry),
                      isCurrent: entry.levelId == currentLevelId,
                      onTap: () => onSelect(entry, _accessFor(entry)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.learnLevelComingLaterBody(currentCode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LevelSegment extends StatelessWidget {
  const _LevelSegment({
    required this.entry,
    required this.access,
    required this.isCurrent,
    required this.onTap,
  });

  final LevelCatalogEntry entry;
  final LevelAccess access;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final code = entry.cefrCode;
    final locked =
        access == LevelAccess.lockedNeedsPrerequisite ||
        access == LevelAccess.notReleased;
    final foreground = isCurrent ? tokens.onPrimaryInk : tokens.textSecondary;

    final label = isCurrent
        ? l10n.learnLevelSemanticsCurrent(code)
        : switch (access) {
            LevelAccess.open => l10n.learnLevelSemanticsOpen(code),
            // noContent can't reach a segment — the track filters those
            // levels out — and an unresolved access already reads locked.
            LevelAccess.lockedNeedsPrerequisite ||
            LevelAccess.notReleased ||
            LevelAccess.noContent => l10n.learnLevelSemanticsLocked(code),
          };

    return Semantics(
      container: true,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isCurrent ? tokens.primaryInk : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locked && !isCurrent) ...[
                    Icon(Icons.lock_rounded, size: 13, color: foreground),
                    const SizedBox(width: AppSpace.xs - 2),
                  ],
                  Text(
                    code,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
