import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// Learn tab landing screen — the CEFR level catalogue. A1 is tappable and
/// opens the guided unit path; A2-C2 are visible but disabled with
/// accessible "Coming Soon" labelling, never selectable as if content
/// exists. See docs/PRODUCT.md and docs/ARCHITECTURE.md.
class LevelCatalogScreen extends StatelessWidget {
  const LevelCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLearn)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in kLevelCatalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LevelCard(entry: entry),
            ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.entry});

  final LevelCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final available = entry.availability == LevelAvailability.available;

    return Semantics(
      button: available,
      enabled: available,
      label: available
          ? entry.cefrCode
          : '${entry.cefrCode} — ${l10n.comingSoon}',
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: available
                ? () => context.go('/learn/${entry.levelId}')
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    entry.cefrCode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (!available)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.comingSoon,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
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
