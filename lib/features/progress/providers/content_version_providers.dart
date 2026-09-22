import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/providers/course_content_providers.dart';
import '../domain/content_drift.dart';
import 'current_learner_provider.dart';
import 'progress_providers.dart';

part 'content_version_providers.g.dart';

/// Records the id snapshot of [levelId]'s loaded bundle, and flags any unit
/// whose content moved under this learner. Returns the unit ids it flagged.
///
/// The read of [ContentVersionRepository.latest] happens **before**
/// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
/// snapshot would be the row just written, every diff would come back
/// empty, and this would quietly do nothing for the rest of the app's life
/// — while every test that only covers a fresh install still passed.
///
/// Fired from `lib/app.dart` for the level the learner is working in. It
/// re-fires when they switch level, because that invalidates
/// `currentLevelIdProvider`. A level they hold progress in but are not
/// currently working in is checked the next time they return to it, which
/// is also the next time they could see a unit row say so — levels load
/// lazily and checking all of them at launch would undo that.
@Riverpod(keepAlive: true)
Future<Set<String>> recordContentVersionAndFlagDrift(
  Ref ref,
  String levelId,
) async {
  final index = await ref.watch(courseContentProvider(levelId).future);
  final learner = await ref.watch(currentLearnerProvider.future);
  final versions = ref.watch(contentVersionRepositoryProvider);
  final bundle = index.bundle;
  final courseId = bundle.course.id;

  final previous = await versions.latest(courseId: courseId);

  await versions.recordIfNew(
    contentVersion: bundle.contentVersion,
    schemaVersion: bundle.schemaVersion,
    courseId: courseId,
    unitIds: index.unitsById.keys.toList(),
    lessonIds: index.lessonsById.keys.toList(),
    // Every activity the index knows, capstones included — a learner has
    // attempts against those too.
    activityIds: index.activitiesById.keys.toList(),
    canDoIds: canDoIdsOf(bundle).toList(),
  );

  // Nothing recorded before means a first install: there is no "before" for
  // anything to have drifted from. The same version loading again is not an
  // update either, and must not recompute — on an ordinary restart the
  // previous row IS this version, so every diff would come back empty and
  // clear a flag the last real upgrade earned.
  if (previous == null || previous.contentVersion == bundle.contentVersion) {
    return const {};
  }

  final drift = contentDriftBetween(
    previous: previous,
    current: bundle,
    currentActivityIds: index.activitiesById.keys.toSet(),
  );

  final attempts = ref.watch(activityAttemptRepositoryProvider);
  final progress = ref.watch(unitLessonProgressRepositoryProvider);

  final stale = drift.isEmpty
      ? const <String>{}
      : staleUnitIds(
          drift: drift,
          attemptedLessonByActivityId: await attempts.attemptedActivityLessons(
            learnerId: learner.id,
          ),
          unitIdByLessonId: index.unitIdByLessonId,
          requiredObjectivesByUnitId: {
            for (final unit in bundle.units)
              unit.id: unit.mastery.requiredObjectives.toSet(),
          },
        );

  // Written even when nothing is stale: this is an upgrade, so a unit the
  // *last* upgrade flagged and this one puts right has to stop saying so.
  await progress.markUnitsContentStale(learnerId: learner.id, unitIds: stale);
  return stale;
}
