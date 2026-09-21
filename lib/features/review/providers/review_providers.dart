import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/index/course_content_index.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../domain/review_content.dart';
import '../domain/weak_spots.dart';

/// Every level the learner has touched, loaded at once — Review is the one
/// tab that spans levels rather than following the current one. See
/// [ReviewContent] for why, and for how an item finds its own level.
///
/// The set of levels comes from the learner's enrolments (plus the base
/// level, where everyone starts, and the level they are in now): a learner
/// can only hold review items or unit progress in a level they have been
/// enrolled in. Deriving it from the item rows themselves would rebuild the
/// whole tab every time a card is rated — for a set that cannot have
/// changed — so the rows are resolved *against* this, not used to build it.
///
/// Each level is loaded on its own and one that fails is left out rather
/// than failing the provider: a learner with A1 and A2 items still reviews
/// the ones that resolve.
final reviewContentProvider = FutureProvider<ReviewContent>((ref) async {
  final catalog = ref.watch(levelCatalogProvider);
  final learner = await ref.watch(currentLearnerProvider.future);
  final enrolments = await ref
      .watch(learnerRepositoryProvider)
      .enrolments(learnerId: learner.id);
  final currentLevelId = await ref.watch(currentLevelIdProvider.future);

  final reached = <String>{
    kBaseLevelId,
    currentLevelId,
    // An enrolment written before levels were tracked has no levelId and
    // means the base level — the only one that existed then.
    for (final enrolment in enrolments) enrolment.levelId ?? kBaseLevelId,
  };

  final indexes = <String, CourseContentIndex>{};
  final cefrCodes = <String, String>{};
  for (final entry in catalog) {
    if (!reached.contains(entry.levelId) || entry.bundleAssetPath == null) {
      continue;
    }
    try {
      indexes[entry.levelId] = await ref.watch(
        courseContentProvider(entry.levelId).future,
      );
      cefrCodes[entry.levelId] = entry.cefrCode;
    } catch (_) {
      // This level's bundle didn't load. Its items can't be rendered, so
      // they drop out of the counts and the session together — the levels
      // that did load stay reviewable.
    }
  }
  return ReviewContent(
    indexesByLevelId: indexes,
    cefrCodesByLevelId: cefrCodes,
  );
});

/// Weak Can-Do goals across every level: for every unit currently
/// `inProgress` — in whichever level it belongs to — the required
/// objectives that don't yet meet the mastery evidence/score threshold,
/// grouped into the lesson that teaches them and labelled with that
/// lesson's level.
///
/// Re-evaluates on demand rather than caching a stale list — units in
/// progress are few, so this stays cheap. See `MasteryAggregationService`.
///
/// A unit id only appears in its own level's bundle, so walking each loaded
/// level's units is itself what files a unit under the right level; each
/// level is also evaluated against its own `masteryPolicy`.
final weakSpotsProvider = FutureProvider<List<WeakSpot>>((ref) async {
  final content = await ref.watch(reviewContentProvider.future);
  final learner = await ref.watch(currentLearnerProvider.future);
  final unitProgress = await ref.watch(allUnitProgressProvider.future);
  final service = ref.watch(masteryAggregationServiceProvider);

  final inProgressUnitIds = unitProgress
      .where((p) => p.state == 'inProgress')
      .map((p) => p.unitId)
      .toSet();

  final spots = <WeakSpot>[];
  for (final MapEntry(key: levelId, value: index)
      in content.indexesByLevelId.entries) {
    final weak = <String>[];
    for (final unit in index.bundle.units) {
      if (!inProgressUnitIds.contains(unit.id)) continue;
      final result = await service.evaluateUnit(
        learnerId: learner.id,
        unit: unit,
        masteryPolicy: index.bundle.domain.masteryPolicy,
      );
      weak.addAll(result.unmasteredObjectiveIds);
    }
    if (weak.isEmpty) continue;
    spots.addAll(
      weakSpotsFor(
        index: index,
        canDoIds: weak,
        levelCode: content.cefrCodesByLevelId[levelId] ?? levelId,
      ),
    );
  }
  return spots;
});

/// Vocabulary/chunk items due for review as of now, across every level —
/// the schedule is one queue, never narrowed to a level.
final dueVocabularyProvider = FutureProvider((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(reviewStateRepositoryProvider);
  return repository.dueVocabulary(learnerId: learner.id, asOf: DateTime.now());
});

/// Just the count of [dueVocabularyProvider] — Home's review-due card and
/// the Review nav-tab badge both need only the number, not the rows.
final dueVocabularyCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(dueVocabularyProvider).whenData((items) => items.length);
});
