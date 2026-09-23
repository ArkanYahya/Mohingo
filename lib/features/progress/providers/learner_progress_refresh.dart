import 'package:flutter_riverpod/misc.dart';

import '../../grammar/providers/grammar_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../review/providers/review_providers.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import 'current_learner_provider.dart';
import 'level_providers.dart';

/// Re-reads every provider built from the current learner's progress —
/// after that progress changed underneath the screens (a reset, or a sync
/// that brought in another device's work).
///
/// Takes the caller's `invalidate` so both a `Ref` and a `WidgetRef` can
/// use it.
void refreshLearnerProgress(
  void Function(ProviderOrFamily provider) invalidate,
) {
  invalidate(currentLearnerProvider);
  invalidate(allUnitProgressProvider);
  invalidate(allLessonProgressProvider);
  invalidate(allVocabularyReviewStateProvider);
  invalidate(allGrammarReviewStateProvider);
  invalidate(reviewContentProvider);
  invalidate(weakSpotsProvider);
  invalidate(dueVocabularyProvider);
  invalidate(currentLevelIdProvider);
  // Families: invalidating the family clears every instance already built.
  invalidate(ensureLevelEnrolmentProvider);
  invalidate(lessonProgressForUnitProvider);
  invalidate(lessonAttemptsForUnitProvider);
  invalidate(currentStreakDaysProvider);
  invalidate(dailyTaskCountsProvider);
  invalidate(latestPlacementAttemptProvider);
  invalidate(latestFinalMissionAttemptProvider);
  invalidate(latestFinalAssessmentAttemptProvider);
}
