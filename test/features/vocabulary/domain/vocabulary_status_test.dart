import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/vocabulary/domain/vocabulary_status.dart';

final _now = DateTime(2026, 9, 18, 12);

VocabularyReviewStateData _row({int repetitions = 1, DateTime? dueAt}) =>
    VocabularyReviewStateData(
      id: 0,
      uuid: 'u',
      learnerId: 1,
      lexiconId: 'w',
      isFavorite: true,
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: repetitions,
      dueAt: dueAt,
      updatedAt: _now,
    );

void main() {
  test('no row, or a row only saved as a favourite, is new', () {
    expect(vocabularyStatus(null, _now), VocabularyStatus.newItem);
    expect(
      vocabularyStatus(_row(repetitions: 0), _now),
      VocabularyStatus.newItem,
    );
  });

  test('anything scheduled at or before now is due — even a word the '
      'learner said "Again" to', () {
    expect(vocabularyStatus(_row(dueAt: _now), _now), VocabularyStatus.due);
    expect(
      vocabularyStatus(
        _row(repetitions: 0, dueAt: _now.subtract(const Duration(hours: 1))),
        _now,
      ),
      VocabularyStatus.due,
    );
  });

  test('scheduled ahead: learning until three successful reviews, then '
      'learned', () {
    final later = _now.add(const Duration(days: 2));
    expect(
      vocabularyStatus(_row(repetitions: 0, dueAt: later), _now),
      VocabularyStatus.learning,
      reason: 'an "Again" answer is in review, not new',
    );
    expect(
      vocabularyStatus(_row(repetitions: 2, dueAt: later), _now),
      VocabularyStatus.learning,
    );
    expect(
      vocabularyStatus(_row(repetitions: 3, dueAt: later), _now),
      VocabularyStatus.learned,
    );
  });
}
