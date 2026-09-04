import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Per-unit lesson-progress rows for one learner — feeds
/// [_UnitOverviewBody]'s per-lesson [StatusIndicator]s. A watchable provider
/// rather than a one-shot [Future] so it can be invalidated (see each lesson
/// row's `onTap`) after returning from the lesson player: the Navigator
/// keeps this screen mounted across a push/pop, so without an explicit
/// invalidate a completed lesson's status would stay stale until some
/// unrelated rebuild happened to occur.
///
/// Declared here rather than in a shared providers file since it has exactly
/// one consumer — see [placementSeedProvider] in `placement_test_screen.dart`
/// for the same single-consumer-provider-lives-with-its-screen convention.
final _lessonProgressForUnitProvider =
    FutureProvider.family<
      List<LessonProgressData>,
      ({int learnerId, String unitId})
    >((ref, params) {
      final repository = ref.watch(unitLessonProgressRepositoryProvider);
      return repository.lessonProgressForUnit(
        learnerId: params.learnerId,
        unitId: params.unitId,
      );
    });

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
    final progressParams = (learnerId: learnerId, unitId: unit.id);
    final progressAsync = ref.watch(
      _lessonProgressForUnitProvider(progressParams),
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
                      onTap: () async {
                        await context.push(
                          '/lesson-player/${unit.id}/${lesson.id}',
                        );
                        // The Navigator keeps this screen mounted across the
                        // push/pop, so the provider must be explicitly
                        // invalidated on return or a freshly completed
                        // lesson's status would stay stale — see
                        // [_lessonProgressForUnitProvider]'s doc comment.
                        ref.invalidate(
                          _lessonProgressForUnitProvider(progressParams),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            StatusIndicator(
                              state: _lessonState(
                                lesson,
                                progressByLessonId[lesson.id],
                              ),
                              size: 20,
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
