import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/database_provider.dart';
import '../data/drift_activity_attempt_repository.dart';
import '../data/drift_assessment_attempt_repository.dart';
import '../data/drift_content_version_repository.dart';
import '../data/drift_daily_task_event_repository.dart';
import '../data/drift_learner_repository.dart';
import '../data/drift_review_state_repository.dart';
import '../data/drift_unit_lesson_progress_repository.dart';
import '../domain/mastery_aggregation_service.dart';
import '../domain/repositories/activity_attempt_repository.dart';
import '../domain/repositories/assessment_attempt_repository.dart';
import '../domain/repositories/content_version_repository.dart';
import '../domain/repositories/daily_task_event_repository.dart';
import '../domain/repositories/learner_repository.dart';
import '../domain/repositories/review_state_repository.dart';
import '../domain/repositories/unit_lesson_progress_repository.dart';

part 'progress_providers.g.dart';

/// Every repository here is bound to its `Drift*` implementation today.
/// Adding a future sync layer means writing a new implementation and
/// changing only these bindings — no caller, and no domain-layer code, needs
/// to change. See docs/ARCHITECTURE.md.
@Riverpod(keepAlive: true)
LearnerRepository learnerRepository(Ref ref) {
  return DriftLearnerRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ActivityAttemptRepository activityAttemptRepository(Ref ref) {
  return DriftActivityAttemptRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
UnitLessonProgressRepository unitLessonProgressRepository(Ref ref) {
  return DriftUnitLessonProgressRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
AssessmentAttemptRepository assessmentAttemptRepository(Ref ref) {
  return DriftAssessmentAttemptRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ReviewStateRepository reviewStateRepository(Ref ref) {
  return DriftReviewStateRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ContentVersionRepository contentVersionRepository(Ref ref) {
  return DriftContentVersionRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
DailyTaskEventRepository dailyTaskEventRepository(Ref ref) {
  return DriftDailyTaskEventRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
MasteryAggregationService masteryAggregationService(Ref ref) {
  return MasteryAggregationService(
    attemptRepository: ref.watch(activityAttemptRepositoryProvider),
    progressRepository: ref.watch(unitLessonProgressRepositoryProvider),
  );
}
