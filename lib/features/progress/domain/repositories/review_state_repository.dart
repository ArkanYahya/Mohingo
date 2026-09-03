import '../../../../data/local/database.dart';

/// Vocabulary/chunk and grammar review state — favourites, confidence
/// markers, and the spaced-review schedule.
///
/// Rows are created lazily on first favourite/review-queue encounter, not
/// pre-populated for every lexicon/chunk/grammar record at enrolment.
/// Marking something reviewed/confident here never grants course mastery —
/// that's tracked separately via [ActivityAttemptRepository]/
/// [MasteryAggregationService]. See docs/DATA_MODEL.md.
abstract interface class ReviewStateRepository {
  Future<VocabularyReviewStateData?> vocabularyState({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
  });

  /// All vocabulary/chunk review rows for the learner — used to render
  /// favourite/due state across a whole list without one query per row.
  Future<List<VocabularyReviewStateData>> allVocabularyState({
    required int learnerId,
  });

  Future<void> setVocabularyFavorite({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required bool isFavorite,
  });

  /// Persists the result of a spaced-review outcome — see
  /// `VocabularyReviewService`/`SpacedReviewScheduler`, which compute
  /// [easeFactor]/[intervalDays]/[repetitions]/[dueAt]; this method only
  /// persists them. Creates the row if none exists yet (e.g. a review
  /// triggered from a word detail screen the learner never favourited).
  Future<void> upsertVocabularyReviewOutcome({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueAt,
    required String confidenceMarker,
  });

  Future<List<VocabularyReviewStateData>> dueVocabulary({
    required int learnerId,
    required DateTime asOf,
  });

  Future<GrammarReviewStateData?> grammarState({
    required int learnerId,
    required String grammarId,
  });

  /// All grammar review rows for the learner — see [allVocabularyState].
  Future<List<GrammarReviewStateData>> allGrammarState({
    required int learnerId,
  });

  Future<void> setGrammarFavorite({
    required int learnerId,
    required String grammarId,
    required bool isFavorite,
  });

  /// A UI-only checkbox — never flips any related Can-Do objective's
  /// mastered state.
  Future<void> markGrammarReviewed({
    required int learnerId,
    required String grammarId,
  });
}
