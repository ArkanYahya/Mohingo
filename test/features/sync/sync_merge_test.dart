import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/sync/domain/sync_merge.dart';
import 'package:mohingo/features/sync/domain/sync_records.dart';

SyncRecord _record(SyncCollection c, Map<String, Object?> fields) =>
    SyncRecord.tryParse(c, c.docIdFor(fields), fields)!;

DateTime _day(int d) => DateTime.utc(2026, 9, d);

void main() {
  void expectCommutative(SyncRecord a, SyncRecord b) {
    expect(mergeRecords(a, b), mergeRecords(b, a));
  }

  group('vocabulary review', () {
    Map<String, Object?> vocab({
      required bool favorite,
      DateTime? favoriteAt,
      required int interval,
      DateTime? reviewedAt,
      required DateTime updatedAt,
    }) => {
      'lexiconId': 'lex-1',
      'isFavorite': favorite,
      'favoriteUpdatedAt': favoriteAt,
      'easeFactor': 2.5,
      'intervalDays': interval,
      'repetitions': interval,
      'lastReviewedAt': reviewedAt,
      'updatedAt': updatedAt,
    };

    test('takes the schedule from the later review and the favourite from '
        'the later toggle', () {
      final favouritedHere = _record(
        SyncCollection.vocabularyReview,
        vocab(
          favorite: true,
          favoriteAt: _day(2),
          interval: 1,
          reviewedAt: _day(1),
          updatedAt: _day(2),
        ),
      );
      final reviewedThere = _record(
        SyncCollection.vocabularyReview,
        vocab(
          favorite: false,
          interval: 6,
          reviewedAt: _day(3),
          updatedAt: _day(3),
        ),
      );
      final merged = mergeRecords(favouritedHere, reviewedThere).fields;
      expect(merged['isFavorite'], isTrue);
      expect(merged['intervalDays'], 6);
      expect(merged['updatedAt'], _day(3));
      expectCommutative(favouritedHere, reviewedThere);
    });

    test('a scheduled-but-never-reviewed copy never overrides a review', () {
      final enrolledOnly = _record(
        SyncCollection.vocabularyReview,
        vocab(favorite: false, interval: 0, updatedAt: _day(9)),
      );
      final reviewed = _record(
        SyncCollection.vocabularyReview,
        vocab(
          favorite: false,
          interval: 3,
          reviewedAt: _day(2),
          updatedAt: _day(2),
        ),
      );
      expect(mergeRecords(enrolledOnly, reviewed).fields['intervalDays'], 3);
    });
  });

  test('grammar keeps the latest "reviewed" mark and the latest favourite', () {
    final a = _record(SyncCollection.grammarReview, {
      'grammarId': 'g',
      'isFavorite': true,
      'favoriteUpdatedAt': _day(5),
      'markedReviewedAt': _day(1),
      'updatedAt': _day(5),
    });
    final b = _record(SyncCollection.grammarReview, {
      'grammarId': 'g',
      'isFavorite': false,
      'favoriteUpdatedAt': _day(2),
      'markedReviewedAt': _day(7),
      'updatedAt': _day(7),
    });
    final merged = mergeRecords(a, b).fields;
    expect(merged['isFavorite'], isTrue);
    expect(merged['markedReviewedAt'], _day(7));
    expectCommutative(a, b);
  });

  test('an enrolment keeps its first start and version, its latest '
      'selection and its earliest unlock', () {
    final a = _record(SyncCollection.enrolments, {
      'levelId': 'a2',
      'courseId': 'EN-A2',
      'contentVersion': 'v1',
      'enrolledAt': _day(1),
      'status': 'active',
      'lastSelectedAt': _day(3),
      'unlockedAt': null,
    });
    final b = _record(SyncCollection.enrolments, {
      'levelId': 'a2',
      'courseId': 'EN-A2',
      'contentVersion': 'v2',
      'enrolledAt': _day(2),
      'status': 'active',
      'lastSelectedAt': _day(4),
      'unlockedAt': _day(2),
    });
    final merged = mergeRecords(a, b).fields;
    expect(merged['contentVersion'], 'v1');
    expect(merged['enrolledAt'], _day(1));
    expect(merged['lastSelectedAt'], _day(4));
    expect(merged['unlockedAt'], _day(2));
    expectCommutative(a, b);
  });

  test('a finished test attempt beats an unfinished copy of it', () {
    final started = _record(SyncCollection.testAttempts, {
      'uuid': 't1',
      'kind': 'placement',
      'startedAt': _day(1),
    });
    final finished = _record(SyncCollection.testAttempts, {
      'uuid': 't1',
      'kind': 'placement',
      'startedAt': _day(1),
      'completedAt': _day(1),
      'outcome': 'startAtUnit',
    });
    expect(mergeRecords(started, finished), finished);
    expect(mergeRecords(finished, started), finished);
  });

  test('an exact tie is broken the same way on every device', () {
    final a = _record(SyncCollection.lessonProgress, {
      'lessonId': 'L',
      'unitId': 'U',
      'state': 'inProgress',
      'lastActivityId': 'A1',
      'updatedAt': _day(1),
    });
    final b = _record(SyncCollection.lessonProgress, {
      'lessonId': 'L',
      'unitId': 'U',
      'state': 'inProgress',
      'lastActivityId': 'A2',
      'updatedAt': _day(1),
    });
    expectCommutative(a, b);
  });
}
