import 'package:flutter/material.dart';

import '../../content/catalog/level_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

/// "Level  A1 A2" — the row that heads the two browsable registry lists
/// (words & phrases, grammar) and says which level's items are on screen.
///
/// This is a **view** filter, exactly as browsing is on the Learn tab: it
/// reports the chosen level to its caller and nothing else. It never calls
/// `LevelSelectionController.select`, so looking at another level's words
/// does not move the learner into that level. That matters in both
/// directions — an A2 learner must still be able to look back at A1's
/// words (they are still in spaced review and still turn up in A2's texts)
/// without leaving A2.
///
/// Only levels that have content are chips; a `comingSoon` level has no
/// registry to show. With fewer than two such levels there is nothing to
/// filter between, so the row — its padding included, which is why it owns
/// that padding rather than the screens — renders as nothing at all.
///
/// The chips carry the bare CEFR code, drawn LTR in both interface
/// languages like every other level control, and each is announced with a
/// noun in front of it ("Level A2" / "المستوى A2").
class LevelFilterChips extends StatelessWidget {
  const LevelFilterChips({
    required this.catalog,
    required this.selectedLevelId,
    required this.onSelect,
    super.key,
  });

  final List<LevelCatalogEntry> catalog;

  /// The level whose items the list is showing — not necessarily the level
  /// the learner is enrolled in.
  final String selectedLevelId;

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    final levels = [
      for (final entry in catalog)
        if (entry.availability != LevelAvailability.comingSoon) entry,
    ];
    if (levels.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xxs,
        AppSpace.md,
        0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
              child: Text(
                l10n.levelFilterLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
            for (final entry in levels)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                child: ChoiceChip(
                  showCheckmark: false,
                  selected: entry.levelId == selectedLevelId,
                  onSelected: (_) => onSelect(entry.levelId),
                  label: Semantics(
                    label: l10n.levelFilterSemantics(entry.cefrCode),
                    child: ExcludeSemantics(
                      child: Text(
                        entry.cefrCode,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
