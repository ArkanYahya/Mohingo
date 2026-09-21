import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../progress/providers/progress_providers.dart';

/// The current learner's latest attempt at each of the three Tests-tab
/// flows — `null` when never attempted. Backs the state line shown on each
/// TestsHomeScreen card. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
final latestPlacementAttemptProvider = FutureProvider<PlacementAttempt?>((
  ref,
) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(assessmentAttemptRepositoryProvider);
  return repository.latestPlacementAttempt(learnerId: learner.id);
});

/// The two capstone providers are asked of the level the learner is in
/// ([currentCourseProvider]), the same level whose mission and assessment
/// the Tests tab shows — an A1 result must never appear under an A2
/// heading.
final latestFinalMissionAttemptProvider = FutureProvider<FinalMissionAttempt?>((
  ref,
) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final course = await ref.watch(currentCourseProvider.future);
  final repository = ref.watch(assessmentAttemptRepositoryProvider);
  return repository.latestFinalMissionAttempt(
    learnerId: learner.id,
    courseId: course.index.bundle.course.id,
  );
});

final latestFinalAssessmentAttemptProvider =
    FutureProvider<FinalAssessmentAttempt?>((ref) async {
      final learner = await ref.watch(currentLearnerProvider.future);
      final course = await ref.watch(currentCourseProvider.future);
      final repository = ref.watch(assessmentAttemptRepositoryProvider);
      return repository.latestFinalAssessmentAttempt(
        learnerId: learner.id,
        courseId: course.index.bundle.course.id,
      );
    });
