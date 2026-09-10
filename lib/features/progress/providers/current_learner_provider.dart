import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/daily_task_event_repository.dart';
import 'progress_providers.dart';

/// The app's single local learner profile, created on first launch if none
/// exists — see docs/adr/0004-local-only-v1-no-firebase-backend.md. Kept
/// alive so every screen reads the same resolved learner rather than
/// re-querying/re-creating it.
///
/// Declared as a plain (non-code-generated) provider: riverpod_generator
/// currently fails (`InvalidTypeException`, verified this session) when
/// asked to generate code for a provider returning a Drift-generated
/// `DataClass` type like [Learner] directly — sidestepped here rather than
/// chased further, since a manual `FutureProvider` works identically for
/// callers.
final currentLearnerProvider = FutureProvider<Learner>((ref) {
  final repository = ref.watch(learnerRepositoryProvider);
  return repository.getOrCreateLearner();
});

/// Consecutive days (ending today) the learner has done at least one
/// activity. Home-only display signal — never used for gating. See
/// [ActivityAttemptRepository.currentStreakDays].
final currentStreakDaysProvider = FutureProvider<int>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(activityAttemptRepositoryProvider);
  return repository.currentStreakDays(
    learnerId: learner.id,
    asOf: DateTime.now(),
  );
});

/// Today's "Tasks today" counts (lesson finished / words reviewed / spoke)
/// for Home's tasks row. See [DailyTaskEventRepository.countsForToday].
final dailyTaskCountsProvider = FutureProvider<DailyTaskCounts>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(dailyTaskEventRepositoryProvider);
  return repository.countsForToday(learnerId: learner.id, asOf: DateTime.now());
});
