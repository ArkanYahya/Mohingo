import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/domain/repositories/daily_task_event_repository.dart';
import 'package:mohingo/features/progress/domain/repositories/review_state_repository.dart';
import 'package:mohingo/features/vocabulary/domain/spaced_review_scheduler.dart';
import 'package:mohingo/features/vocabulary/domain/vocabulary_review_service.dart';

class _FakeDailyTaskEventRepository implements DailyTaskEventRepository {
  final List<({int learnerId, DailyTaskType taskType})> recorded = [];

  @override
  Future<void> recordEvent({
    required int learnerId,
    required DailyTaskType taskType,
    DateTime? occurredAt,
  }) async {
    recorded.add((learnerId: learnerId, taskType: taskType));
  }

  @override
  Future<DailyTaskCounts> countsForToday({
    required int learnerId,
    required DateTime asOf,
  }) async => (lesson: 0, vocabularyReview: 0, speaking: 0);
}

class _FakeReviewStateRepository implements ReviewStateRepository {
  VocabularyReviewStateData? stored;
  final List<
    ({double ease, int interval, int reps, DateTime due, String marker})
  >
  recordedOutcomes = [];

  @override
  Future<VocabularyReviewStateData?> vocabularyState({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
  }) async => stored;

  @override
  Future<void> upsertVocabularyReviewOutcome({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueAt,
    required String confidenceMarker,
  }) async {
    recordedOutcomes.add((
      ease: easeFactor,
      interval: intervalDays,
      reps: repetitions,
      due: dueAt,
      marker: confidenceMarker,
    ));
  }

  @override
  Future<List<VocabularyReviewStateData>> allVocabularyState({
    required int learnerId,
  }) async => stored == null ? const [] : [stored!];

  @override
  Future<void> setVocabularyFavorite({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required bool isFavorite,
  }) async {}

  @override
  Future<List<VocabularyReviewStateData>> dueVocabulary({
    required int learnerId,
    required DateTime asOf,
  }) async => const [];

  @override
  Future<GrammarReviewStateData?> grammarState({
    required int learnerId,
    required String grammarId,
  }) async => null;

  @override
  Future<List<GrammarReviewStateData>> allGrammarState({
    required int learnerId,
  }) async => const [];

  @override
  Future<void> setGrammarFavorite({
    required int learnerId,
    required String grammarId,
    required bool isFavorite,
  }) async {}

  @override
  Future<void> markGrammarReviewed({
    required int learnerId,
    required String grammarId,
  }) async {}
}

void main() {
  test('a first-ever review starts from the default ease factor 2.5, 0 '
      'repetitions, 0 interval', () async {
    final repo = _FakeReviewStateRepository();
    final service = VocabularyReviewService(
      repository: repo,
      dailyTaskEventRepository: _FakeDailyTaskEventRepository(),
    );
    final now = DateTime.utc(2026, 9, 2);

    await service.recordReview(
      learnerId: 1,
      lexiconId: 'A1.LEX.HELLO.INTJ',
      quality: ReviewQuality.good,
      now: now,
    );

    expect(repo.recordedOutcomes, hasLength(1));
    final outcome = repo.recordedOutcomes.single;
    expect(outcome.reps, 1);
    expect(outcome.interval, 1);
    expect(outcome.marker, 'good');
  });

  test('a subsequent review continues from the persisted schedule, not '
      'from defaults', () async {
    final repo = _FakeReviewStateRepository()
      ..stored = VocabularyReviewStateData(
        id: 1,
        uuid: 'x',
        learnerId: 1,
        lexiconId: 'A1.LEX.HELLO.INTJ',
        isFavorite: false,
        easeFactor: 2.5,
        intervalDays: 6,
        repetitions: 2,
        updatedAt: DateTime.utc(2026, 9, 1),
      );
    final service = VocabularyReviewService(
      repository: repo,
      dailyTaskEventRepository: _FakeDailyTaskEventRepository(),
    );
    final now = DateTime.utc(2026, 9, 2);

    await service.recordReview(
      learnerId: 1,
      lexiconId: 'A1.LEX.HELLO.INTJ',
      quality: ReviewQuality.good,
      now: now,
    );

    final outcome = repo.recordedOutcomes.single;
    expect(outcome.reps, 3);
    expect(
      outcome.interval,
      15,
    ); // round(6 * 2.5), not the 1st-repetition default
  });

  test(
    'recording a review also records a vocabularyReview daily-task event — '
    'feeds Home\'s "Review 5 words" task, regardless of confidence quality',
    () async {
      final repo = _FakeReviewStateRepository();
      final dailyTaskEvents = _FakeDailyTaskEventRepository();
      final service = VocabularyReviewService(
        repository: repo,
        dailyTaskEventRepository: dailyTaskEvents,
      );

      await service.recordReview(
        learnerId: 7,
        lexiconId: 'A1.LEX.HELLO.INTJ',
        quality: ReviewQuality.again,
        now: DateTime.utc(2026, 9, 2),
      );

      expect(dailyTaskEvents.recorded, hasLength(1));
      expect(dailyTaskEvents.recorded.single.learnerId, 7);
      expect(
        dailyTaskEvents.recorded.single.taskType,
        DailyTaskType.vocabularyReview,
      );
    },
  );
}
