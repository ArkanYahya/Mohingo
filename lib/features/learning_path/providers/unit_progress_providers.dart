import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// All A1 unit-progress rows for the current learner. Invalidate (see
/// `ref.invalidate`) whenever
/// `MasteryAggregationService.refreshUnitProgress` runs, so the Learn tab
/// and Home reflect fresh state after a lesson.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final allUnitProgressProvider = FutureProvider<List<UnitProgressData>>((
  ref,
) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(unitLessonProgressRepositoryProvider);
  return repository.allUnitProgress(learnerId: learner.id);
});

/// Every lesson-progress row for one learner, across all units — feeds
/// `currentUnitId`'s "most recently active unit" heuristic (Learn spine and
/// Home's "Continue" card).
///
/// Invalidated from the same place as [lessonProgressForUnitProvider] —
/// `LessonPlayerScreen._handleSubmitted`, which runs on every activity
/// submission, so the current-unit position can move on before a unit is
/// even finished, not just when one is completed.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final allLessonProgressProvider = FutureProvider<List<LessonProgressData>>((
  ref,
) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(unitLessonProgressRepositoryProvider);
  return repository.allLessonProgress(learnerId: learner.id);
});

/// Per-unit lesson-progress rows for one learner — feeds
/// `UnitOverviewScreen`'s per-lesson `StatusIndicator`s.
///
/// Lives here, beside [allUnitProgressProvider], because invalidation is
/// owned by the *writer* rather than the reader: `LessonPlayerScreen`
/// invalidates both providers at the one point where lesson progress
/// actually changes (finishing a lesson's last activity). That is the only
/// correct trigger — the lesson player can leave via `pop` ("Back to unit")
/// *or* `pushReplacement` ("Next lesson"), and go_router's
/// `pushReplacement` never completes the replaced route's future, so a
/// reader-side `await context.push(...)`-then-invalidate would silently
/// stop firing forever after the first "Next lesson" tap. Invalidating from
/// the writer works for both exits: `UnitOverviewScreen` watches this
/// provider, so Riverpod rebuilds it with fresh data regardless of what the
/// Navigator does.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final lessonProgressForUnitProvider =
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

/// Every recorded attempt across one unit's lessons, for one learner —
/// feeds `lessonStatus`'s "did every activity's most recent attempt come
/// out correct" check on `UnitOverviewScreen`.
///
/// Invalidated alongside [lessonProgressForUnitProvider], from the same
/// writer (`LessonPlayerScreen._handleSubmitted`) and for the same reason:
/// see that provider's doc comment.
final lessonAttemptsForUnitProvider =
    FutureProvider.family<
      List<ActivityAttempt>,
      ({int learnerId, String unitId})
    >((ref, params) async {
      final index = await ref.watch(courseContentProvider('a1').future);
      final unit = index.unitsById[params.unitId];
      final lessonIds = <String>[
        for (final lesson in unit?.lessons ?? const []) lesson.id,
      ];
      final repository = ref.watch(activityAttemptRepositoryProvider);
      return repository.attemptsForLessons(
        learnerId: params.learnerId,
        lessonIds: lessonIds,
      );
    });
