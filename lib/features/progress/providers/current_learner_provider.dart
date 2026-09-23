import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../account/providers/account_providers.dart';
import '../domain/repositories/daily_task_event_repository.dart';
import 'progress_providers.dart';

/// The learner on screen: the guest, or the signed-in account's own
/// learner — whichever [accountSessionProvider] says owns the session (see
/// docs/adr/0010-optional-accounts-and-progress-sync.md). Every
/// learner-scoped provider watches this, so signing in or out re-reads all
/// of them for the new owner. Kept alive so every screen reads the same
/// resolved learner rather than re-querying it.
///
/// Declared as a plain (non-code-generated) provider: riverpod_generator
/// currently fails (`InvalidTypeException`, verified this session) when
/// asked to generate code for a provider returning a Drift-generated
/// `DataClass` type like [Learner] directly — sidestepped here rather than
/// chased further, since a manual `FutureProvider` works identically for
/// callers.
final currentLearnerProvider = FutureProvider<Learner>((ref) async {
  final session = await ref.watch(accountSessionProvider.future);
  final repository = ref.watch(learnerRepositoryProvider);
  return repository.learnerById(session.learnerId);
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
