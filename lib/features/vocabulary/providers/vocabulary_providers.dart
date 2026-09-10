import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../domain/vocabulary_review_service.dart';

part 'vocabulary_providers.g.dart';

@Riverpod(keepAlive: true)
VocabularyReviewService vocabularyReviewService(Ref ref) {
  return VocabularyReviewService(
    repository: ref.watch(reviewStateRepositoryProvider),
    dailyTaskEventRepository: ref.watch(dailyTaskEventRepositoryProvider),
  );
}

/// All vocabulary/chunk review rows for the current learner — used to
/// render favourite/due state across the Vocabulary list without one query
/// per row. Declared as a plain provider — see [currentLearnerProvider]'s
/// doc comment for why (riverpod_generator fails on Drift `DataClass`
/// return types).
final allVocabularyReviewStateProvider =
    FutureProvider<List<VocabularyReviewStateData>>((ref) async {
      final learner = await ref.watch(currentLearnerProvider.future);
      final repository = ref.watch(reviewStateRepositoryProvider);
      return repository.allVocabularyState(learnerId: learner.id);
    });
