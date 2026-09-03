import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../learning_path/providers/unit_progress_providers.dart';

/// Home tab landing screen. Built around the next useful action — the
/// "Continue learning" card — rather than decorative statistics, per
/// docs/PRODUCT.md's Home requirements. Vocabulary/Grammar quick actions,
/// "Today's review", and the compact levels section are Phase 7+ scope
/// (Review feature) — not built here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final masteredUnitIds = {
            for (final p in progressAsync.value ?? const [])
              if (p.state == 'mastered') p.unitId,
          };
          final nextUnit = index.bundle.units
              .where((u) => !masteredUnitIds.contains(u.id))
              .firstOrNull;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: nextUnit == null
                ? Center(child: Text(l10n.homeAllUnitsMastered))
                : _ContinueLearningCard(
                    title: nextUnit.title,
                    titleAr: nextUnit.titleAr,
                    onContinue: () =>
                        context.go('/learn/a1/unit/${nextUnit.id}'),
                  ),
          );
        },
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.title,
    required this.titleAr,
    required this.onContinue,
  });

  final String title;
  final String titleAr;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.continueLearningTitle,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            Text(
              titleAr,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: Text(l10n.continueLearningCta),
            ),
          ],
        ),
      ),
    );
  }
}
