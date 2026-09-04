import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../learning_path/providers/unit_progress_providers.dart';

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

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.entry});

  final LevelCatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final available = entry.availability == LevelAvailability.available;

    (int mastered, int total)? progress;
    if (available) {
      final contentAsync = ref.watch(courseContentProvider(entry.levelId));
      final progressAsync = ref.watch(allUnitProgressProvider);
      final total = contentAsync.value?.bundle.units.length;
      if (total != null) {
        final mastered = (progressAsync.value ?? const [])
            .where((p) => p.state == 'mastered')
            .length;
        progress = (mastered, total);
      }
    }

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.cefrCode,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (progress != null)
                          Text(
                            l10n.homeLevelProgressCaption(
                              progress.$1,
                              progress.$2,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
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
