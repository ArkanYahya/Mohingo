import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/sync/domain/cloud_progress_store.dart';
import 'package:mohingo/features/sync/domain/sync_records.dart';

void main() {
  test('parsing coerces cloud number types and keeps times in UTC', () {
    final record = SyncRecord.tryParse(SyncCollection.vocabularyReview, 'x', {
      'lexiconId': 'lex',
      'isFavorite': false,
      'easeFactor': 3, // an int that is really a double
      'intervalDays': 4.0, // a double that is really an int
      'repetitions': 1,
      'updatedAt': DateTime(2026, 9, 23, 10),
    })!;
    expect(record.fields['easeFactor'], 3.0);
    expect(record.fields['intervalDays'], 4);
    expect((record.fields['updatedAt']! as DateTime).isUtc, isTrue);
    expect(record.fields['chunkId'], isNull);
  });

  test(
    'a record with a missing required field or a wrong type is rejected',
    () {
      expect(
        SyncRecord.tryParse(SyncCollection.dailyTasks, 'x', {
          'uuid': 'x',
          'taskType': 'lesson',
        }),
        isNull,
      );
      expect(
        SyncRecord.tryParse(SyncCollection.attempts, 'x', {
          'uuid': 'x',
          'canDoIds': ['a', 3],
        }),
        isNull,
      );
    },
  );

  test('unknown cloud fields are dropped, never carried into the app', () {
    final record = SyncRecord.tryParse(SyncCollection.dailyTasks, 'x', {
      'uuid': 'x',
      'taskType': 'lesson',
      'occurredAt': DateTime.utc(2026),
      'epoch': 3,
      'serverUpdatedAt': DateTime.utc(2026),
    })!;
    expect(record.fields.keys, {'uuid', 'taskType', 'occurredAt'});
  });

  test('document ids are natural keys and can never open a sub-path', () {
    expect(
      SyncCollection.vocabularyReview.docIdFor({'lexiconId': 'a/b'}),
      'lexicon%3Aa%2Fb',
    );
    expect(
      SyncCollection.vocabularyReview.docIdFor({'chunkId': 'c1'}),
      'chunk%3Ac1',
    );
    expect(SyncCollection.lessonProgress.docIdFor({'lessonId': 'L1'}), 'L1');
  });

  test('a pull cursor round-trips through JSON', () {
    final cursor = PullCursor(DateTime.utc(2026, 9, 23, 1, 2, 3, 4, 5), 'd1');
    final back = PullCursor.fromJson(cursor.toJson())!;
    expect(back.serverUpdatedAt, cursor.serverUpdatedAt);
    expect(back.docId, 'd1');
    expect(PullCursor.fromJson('junk'), isNull);
  });
}
