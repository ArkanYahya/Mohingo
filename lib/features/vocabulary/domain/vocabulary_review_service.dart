// Constructor param intentionally doesn't match the private field name
// (kept readable at call sites, e.g. `repository:`) — an initializing
// formal would force the underscored field name into the public API.
// ignore_for_file: prefer_initializing_formals

import '../../progress/domain/repositories/daily_task_event_repository.dart';
import '../../progress/domain/repositories/review_state_repository.dart';
import 'spaced_review_scheduler.dart';

/// Applies one review outcome: reads the item's current schedule (if any),
/// computes the next one via [SpacedReviewScheduler], and persists it.
/// Exactly one of [lexiconId]/[chunkId] must be set.
class VocabularyReviewService {
  VocabularyReviewService({
    required ReviewStateRepository repository,
    required DailyTaskEventRepository dailyTaskEventRepository,
  }) : _repository = repository,
       _dailyTaskEventRepository = dailyTaskEventRepository;

  final ReviewStateRepository _repository;
  final DailyTaskEventRepository _dailyTaskEventRepository;

  Future<void> recordReview({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required ReviewQuality quality,
    DateTime? now,
  }) async {
    assert(
      (lexiconId == null) != (chunkId == null),
      'exactly one of lexiconId/chunkId must be set',
    );
    final effectiveNow = now ?? DateTime.now();
    final existing = await _repository.vocabularyState(
      learnerId: learnerId,
      lexiconId: lexiconId,
      chunkId: chunkId,
    );

    final schedule = SpacedReviewScheduler.schedule(
      currentEaseFactor: existing?.easeFactor ?? 2.5,
      currentIntervalDays: existing?.intervalDays ?? 0,
      currentRepetitions: existing?.repetitions ?? 0,
      quality: quality,
      now: effectiveNow,
    );

    await _repository.upsertVocabularyReviewOutcome(
      learnerId: learnerId,
      lexiconId: lexiconId,
      chunkId: chunkId,
      easeFactor: schedule.easeFactor,
      intervalDays: schedule.intervalDays,
      repetitions: schedule.repetitions,
      dueAt: schedule.dueAt,
      confidenceMarker: quality.name,
    );

    // Feeds Home's "Review 5 words" daily task — every graded word counts
    // once, regardless of confidence quality.
    await _dailyTaskEventRepository.recordEvent(
      learnerId: learnerId,
      taskType: DailyTaskType.vocabularyReview,
      occurredAt: effectiveNow,
    );
  }
}
