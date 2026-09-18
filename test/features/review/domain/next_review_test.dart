import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/review/domain/next_review.dart';

VocabularyReviewStateData _state(DateTime? dueAt) => VocabularyReviewStateData(
  id: 0,
  uuid: 'u',
  learnerId: 1,
  lexiconId: 'w',
  isFavorite: false,
  easeFactor: 2.5,
  intervalDays: 1,
  repetitions: 1,
  dueAt: dueAt,
  updatedAt: DateTime(2026),
);

void main() {
  final now = DateTime(2026, 9, 18, 21, 30);

  test('counts calendar days to the soonest future review', () {
    expect(
      daysUntilNextReview([
        _state(DateTime(2026, 9, 25, 8)),
        _state(DateTime(2026, 9, 19, 7)),
      ], now),
      1,
    );
  });

  test('a review later today is 0 days away', () {
    expect(daysUntilNextReview([_state(DateTime(2026, 9, 18, 23))], now), 0);
  });

  test('ignores items already due and items with no schedule', () {
    expect(
      daysUntilNextReview([
        _state(DateTime(2026, 9, 17)),
        _state(null),
        _state(DateTime(2026, 9, 21, 9)),
      ], now),
      3,
    );
  });

  test('null when nothing is scheduled ahead', () {
    expect(daysUntilNextReview([_state(null)], now), isNull);
    expect(daysUntilNextReview(const [], now), isNull);
  });
}
