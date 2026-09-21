import '../../../data/local/database.dart';
import 'review_content.dart';

/// One due word or phrase, resolved against the level its own id belongs to
/// so it can be shown.
class ReviewCard {
  const ReviewCard({
    required this.state,
    required this.text,
    required this.arabic,
    required this.isPhrase,
    this.example,
  });

  final VocabularyReviewStateData state;
  final String text;
  final String arabic;
  final bool isPhrase;
  final String? example;

  /// The card for [state], or null when its level isn't loaded or its id no
  /// longer resolves there.
  static ReviewCard? of(ReviewContent content, VocabularyReviewStateData s) {
    final lexiconId = s.lexiconId;
    if (lexiconId != null) {
      final item = content.lexicon(lexiconId);
      if (item == null) return null;
      return ReviewCard(
        state: s,
        text: item.headword,
        arabic: item.arabic,
        isPhrase: false,
        example: item.examples.firstOrNull?.en,
      );
    }
    final chunkId = s.chunkId;
    if (chunkId == null) return null;
    final item = content.chunk(chunkId);
    if (item == null) return null;
    return ReviewCard(
      state: s,
      text: item.text,
      arabic: item.arabic,
      isPhrase: true,
    );
  }
}

/// The due items that can actually be shown, oldest first.
///
/// The Review tab's count and the review session's cards are this one list,
/// deliberately: the number on the tab is then never a promise the session
/// can't keep. Before levels, the tab counted the learner's whole schedule
/// while the session resolved only A1's bundle, so an A2 word was counted
/// on the tab and then missing from the session it opened.
///
/// An item whose level failed to load drops out of both together, so a
/// learner with A1 and A2 items still reviews the ones that resolve.
List<ReviewCard> reviewCardsFor({
  required ReviewContent content,
  required List<VocabularyReviewStateData> due,
}) {
  final sorted = [
    ...due,
  ]..sort((a, b) => (a.dueAt ?? DateTime(0)).compareTo(b.dueAt ?? DateTime(0)));
  return [for (final s in sorted) ?ReviewCard.of(content, s)];
}
