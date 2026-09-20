import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../domain/level_access.dart';
import 'current_learner_provider.dart';
import 'progress_providers.dart';

part 'level_providers.g.dart';

/// Ensures the learner has an enrolment row for [levelId] once its content
/// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.
@Riverpod(keepAlive: true)
Future<void> ensureLevelEnrolment(Ref ref, String levelId) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final index = await ref.watch(courseContentProvider(levelId).future);
  await ref
      .watch(learnerRepositoryProvider)
      .ensureEnrolled(
        learnerId: learner.id,
        levelId: levelId,
        courseId: index.bundle.course.id,
        contentVersion: index.bundle.contentVersion,
      );
}

/// The level the learner is working in — see [currentLevelIdFor]. Every
/// screen that shows "a level" follows this rather than naming one.
@Riverpod(keepAlive: true)
Future<String> currentLevelId(Ref ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final enrolments = await ref
      .watch(learnerRepositoryProvider)
      .enrolments(learnerId: learner.id);
  return currentLevelIdFor(
    enrolments: enrolments,
    catalog: ref.watch(levelCatalogProvider),
  );
}

/// Whether [levelId] is open for the learner right now, and if not, why.
@riverpod
Future<LevelAccess> levelAccess(Ref ref, String levelId) async {
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null) return LevelAccess.noContent;
  // levelAccessFor's answer for a not-yet-available level never reads
  // enrolment or prerequisite state, so don't fetch either — the learner
  // and the repository call below are real DB work.
  if (entry.availability != LevelAvailability.available) {
    return levelAccessFor(
      entry: entry,
      enrolment: null,
      prerequisiteComplete: false,
    );
  }

  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(learnerRepositoryProvider);
  final enrolment = await repository.enrolmentForLevel(
    learnerId: learner.id,
    levelId: levelId,
  );

  var prerequisiteComplete = false;
  final prerequisiteId = entry.prerequisiteLevelId;
  if (prerequisiteId != null) {
    final prerequisite = await ref.watch(
      courseContentProvider(prerequisiteId).future,
    );
    final progress = await ref.watch(allUnitProgressProvider.future);
    prerequisiteComplete = levelComplete(
      units: prerequisite.bundle.units,
      masteredUnitIds: {
        for (final row in progress)
          if (row.state == 'mastered') row.unitId,
      },
    );
  }

  return levelAccessFor(
    entry: entry,
    enrolment: enrolment,
    prerequisiteComplete: prerequisiteComplete,
  );
}

/// Switching levels and opening a locked one — the two writes behind the
/// Learn tab's level strip and its lock sheet.
///
/// `keepAlive`: without it, a caller that only ever does
/// `ref.read(levelSelectionControllerProvider.notifier).select(...)` holds no
/// listener on the controller itself, so plain `@riverpod`'s auto-dispose
/// tears it down — `ref` included — the moment the synchronous part of that
/// read returns, which is *before* `select`/`unlock`'s own `await`s finish
/// (verified: it throws "Cannot use the Ref ... after it has been disposed"
/// partway through `select`). Nothing here is per-argument state that ought
/// to be discarded, so staying alive for the app's life costs nothing.
@Riverpod(keepAlive: true)
class LevelSelectionController extends _$LevelSelectionController {
  @override
  void build() {}

  /// Makes [levelId] the level the learner is working in, enrolling them if
  /// this is their first time in it.
  Future<void> select(String levelId) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref.read(ensureLevelEnrolmentProvider(levelId).future);
    await ref
        .read(learnerRepositoryProvider)
        .markLevelSelected(learnerId: learner.id, levelId: levelId);
    ref.invalidate(currentLevelIdProvider);
  }

  /// Opens [levelId] for the learner — from "Open anyway", from finishing
  /// the level it builds on, or from a placement result inside it.
  Future<void> unlock(String levelId) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref.read(ensureLevelEnrolmentProvider(levelId).future);
    await ref
        .read(learnerRepositoryProvider)
        .markLevelUnlocked(learnerId: learner.id, levelId: levelId);
    ref.invalidate(levelAccessProvider(levelId));
  }
}
