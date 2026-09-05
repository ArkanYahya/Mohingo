import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../domain/current_unit_selector.dart';
import '../providers/unit_progress_providers.dart';

/// The A1 guided unit path (U0-U12), rendered as a vertical journey spine:
/// one node per unit, larger "milestone" nodes for units with a mission
/// lesson, and a "you are here" marker at the learner's current position.
/// State badges are a recommendation, never a hard lock: every unit is
/// always tappable, per docs/PRODUCT.md flow 5. There is no Block/chapter
/// entity in the real curriculum data (see [Unit]'s doc comment) — milestone
/// grouping is derived from mission lessons, not a chapter boundary. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
class UnitPathView extends ConsumerWidget {
  const UnitPathView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);
    final lessonProgressAsync = ref.watch(allLessonProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('A1')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final progressByUnitId = {
            for (final p in progressAsync.value ?? const []) p.unitId: p,
          };
          final units = index.bundle.units;
          final masteredIds = <String>{
            for (final p in progressByUnitId.values)
              if (p.state == 'mastered') p.unitId,
          };
          final currentUnit = currentUnitId(
            units: units,
            masteredUnitIds: masteredIds,
            allLessonProgress: lessonProgressAsync.value ?? const [],
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: units.length,
            itemBuilder: (context, i) {
              final unit = units[i];
              return _SpineTile(
                unit: unit,
                state: ProgressState.fromRaw(progressByUnitId[unit.id]?.state),
                isMilestone: unit.lessons.any((l) => l.lessonType == 'mission'),
                isCurrent: unit.id == currentUnit,
                isFirst: i == 0,
                isLast: i == units.length - 1,
                onTap: () => context.go('/learn/a1/unit/${unit.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpineTile extends StatelessWidget {
  const _SpineTile({
    required this.unit,
    required this.state,
    required this.isMilestone,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Unit unit;
  final ProgressState state;
  final bool isMilestone;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final railColor = colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Expanded(
                      child: isFirst
                          ? const SizedBox.shrink()
                          : Container(width: 2, color: railColor),
                    ),
                    StatusIndicator(state: state, size: isMilestone ? 32 : 22),
                    Expanded(
                      child: isLast
                          ? const SizedBox.shrink()
                          : Container(width: 2, color: railColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.unitPathYouAreHere,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                ),
                          ),
                        ),
                      Text(
                        unit.title,
                        textDirection: TextDirection.ltr,
                        style: isMilestone
                            ? Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)
                            : Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        unit.titleAr,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
