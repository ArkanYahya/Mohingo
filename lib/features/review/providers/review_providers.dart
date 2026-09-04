import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Weak Can-Do objectives: for every unit currently `inProgress`, the
/// required objectives that don't yet meet the mastery evidence/score
/// threshold. Re-evaluates on demand rather than caching a stale list —
/// units in progress are few, so this stays cheap. See
/// `MasteryAggregationService`.
final weakObjectivesProvider = FutureProvider<List<String>>((ref) async {
  final index = await ref.watch(courseContentProvider('a1').future);
  final learner = await ref.watch(currentLearnerProvider.future);
  final unitProgress = await ref.watch(allUnitProgressProvider.future);
  final service = ref.watch(masteryAggregationServiceProvider);

  final inProgressUnitIds = unitProgress
      .where((p) => p.state == 'inProgress')
      .map((p) => p.unitId)
      .toSet();

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
  return weak;
});

/// Vocabulary/chunk items due for review as of now.
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
