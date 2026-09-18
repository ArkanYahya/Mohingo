import '../../../data/local/database.dart';

/// Where one word or phrase stands in the learner's spaced review.
enum VocabularyStatus {
  /// Not in review yet (never rated — at most saved as a favourite).
  newItem,

  /// Scheduled for now or earlier.
  due,

  /// In review, scheduled ahead, fewer than three successful reviews.
  learning,

  /// Three or more successful reviews in a row, scheduled ahead. A memory
  /// outcome only — never course mastery (docs/GLOSSARY.md).
  learned,
}

/// The status of the item whose review row is [state] (null: no row), as
/// of [now]. "Due" matches the review queue (`dueVocabulary`): anything
/// scheduled at or before [now], however many times it has been recalled.
VocabularyStatus vocabularyStatus(
  VocabularyReviewStateData? state,
  DateTime now,
) {
  final due = state?.dueAt;
  if (state == null || due == null) return VocabularyStatus.newItem;
  if (!due.isAfter(now)) return VocabularyStatus.due;
  if (state.repetitions >= 3) return VocabularyStatus.learned;
  return VocabularyStatus.learning;
}
