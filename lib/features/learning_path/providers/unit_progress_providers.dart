import 'package:flutter_riverpod/flutter_riverpod.dart';

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
