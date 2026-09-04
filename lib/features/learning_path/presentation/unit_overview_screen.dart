import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../providers/unit_progress_providers.dart';

/// Shows one unit's lessons, each with a [StatusIndicator] derived from
/// whether the learner's recorded position in that lesson has reached its
/// final activity. Every lesson is always tappable — free access, no hard
/// lock — per docs/PRODUCT.md flow 5. Revisiting a completed lesson replays
/// it from the start and appends fresh evidence rather than overwriting
/// history; see docs/DATA_MODEL.md.
class UnitOverviewScreen extends ConsumerWidget {
  const UnitOverviewScreen({required this.unitId, super.key});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final unit = index.unitsById[unitId];
        if (unit == null) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }
        return learnerAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
          data: (learner) =>
              _UnitOverviewBody(unit: unit, learnerId: learner.id),
        );
      },
    );
  }
}

class _UnitOverviewBody extends ConsumerWidget {
  const _UnitOverviewBody({required this.unit, required this.learnerId});

  final Unit unit;
  final int learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(
      lessonProgressForUnitProvider((learnerId: learnerId, unitId: unit.id)),
    );

    return progressAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (rows) {
        final progressByLessonId = {for (final row in rows) row.lessonId: row};

        return Scaffold(
          appBar: AppBar(title: Text(unit.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lesson in unit.lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      // No invalidate-on-return here: the lesson player
                      // invalidates [lessonProgressForUnitProvider] itself
                      // the moment a lesson is finished, which covers both
                      // its "Back to unit" (pop) and "Next lesson"
                      // (pushReplacement) exits. See that provider's doc
                      // comment.
                      onTap: () => context.push(
                        '/lesson-player/${unit.id}/${lesson.id}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _lessonStatusIndicator(
                              context,
                              lesson,
                              progressByLessonId[lesson.id],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    textDirection: TextDirection.ltr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    lesson.titleAr,
                                    textDirection: TextDirection.rtl,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The lesson row's status dot. A finished lesson deliberately announces
  /// "Completed" rather than the shared "Mastered" label: reaching a
  /// lesson's last activity is not course mastery as docs/GLOSSARY.md
  /// defines it (that is `MasteryAggregationService`'s call, made per unit
  /// against Can-Do evidence). See [StatusIndicator.semanticLabelOverride].
  Widget _lessonStatusIndicator(
    BuildContext context,
    Lesson lesson,
    LessonProgressData? row,
  ) {
    final state = _lessonState(lesson, row);
    return StatusIndicator(
      state: state,
      size: 20,
      semanticLabelOverride: state == ProgressState.mastered
          ? AppLocalizations.of(context)!.lessonStateCompleted
          : null,
    );
  }

  /// A lesson with no recorded position is [ProgressState.notStarted]; one
  /// whose last recorded activity is its final activity is
  /// [ProgressState.mastered] (the lesson player's own "reached the last
  /// activity" resume rule — see `lesson_player_screen.dart`); anything else
  /// recorded is [ProgressState.inProgress].
  ProgressState _lessonState(Lesson lesson, LessonProgressData? row) {
    if (row == null || lesson.activities.isEmpty) {
      return ProgressState.notStarted;
    }
    final lastActivityId = row.lastActivityId;
    if (lastActivityId != null && lastActivityId == lesson.activities.last.id) {
      return ProgressState.mastered;
    }
    return ProgressState.inProgress;
  }
}
