import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// All grammar review rows for the current learner — used to render
/// favourite/reviewed state across the Grammar list without one query per
/// row. Declared as a plain provider — see [currentLearnerProvider]'s doc
/// comment for why (riverpod_generator fails on Drift `DataClass` return
/// types).
final allGrammarReviewStateProvider =
    FutureProvider<List<GrammarReviewStateData>>((ref) async {
      final learner = await ref.watch(currentLearnerProvider.future);
      final repository = ref.watch(reviewStateRepositoryProvider);
      return repository.allGrammarState(learnerId: learner.id);
    });
