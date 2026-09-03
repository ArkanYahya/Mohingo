import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../providers/unit_progress_providers.dart';

/// The A1 guided unit path (U0-U12) — each unit shows a state badge
/// (not started / in progress / mastered) sourced from the
/// `unit_progress` read-model, never a hard lock: every unit is always
/// tappable, per the free-access model. See docs/PRODUCT.md flow 5.
class UnitPathView extends ConsumerWidget {
  const UnitPathView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('A1')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final progressByUnitId = {
            for (final p in progressAsync.value ?? const []) p.unitId: p,
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final unit in index.bundle.units)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UnitTile(
                    unit: unit,
                    state: progressByUnitId[unit.id]?.state,
                    l10n: l10n,
                    onTap: () => context.go('/learn/a1/unit/${unit.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.state,
    required this.l10n,
    required this.onTap,
  });

  final Unit unit;
  final String? state;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (String label, Color color) = switch (state) {
      'mastered' => (l10n.unitStateMastered, colorScheme.primary),
      'inProgress' => (l10n.unitStateInProgress, colorScheme.tertiary),
      _ => (l10n.unitStateNotStarted, colorScheme.onSurfaceVariant),
    };

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      textDirection: TextDirection.ltr,
                    ),
                    Text(
                      unit.titleAr,
                      style: Theme.of(context).textTheme.bodySmall,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
