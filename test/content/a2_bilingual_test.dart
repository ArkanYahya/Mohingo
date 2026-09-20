import 'package:flutter_test/flutter_test.dart';

import 'a2_finished_units.dart';

final _arabic = RegExp(r'[؀-ۿ]');

void main() {
  test('every conversation line carries Arabic', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final line in lesson.encounterDialogue) {
          expect(
            line.ar.trim(),
            isNotEmpty,
            reason: '${lesson.id} line by ${line.speaker}',
          );
        }
      }
    }
  });

  test('every activity prompt carries Arabic', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        expect(a.promptAr?.trim() ?? '', isNotEmpty, reason: a.id);
      }
    }
  });

  test('a bilingual field that is present but not a String fails the gate', () {
    // The parser deliberately degrades a non-String bilingual field to null
    // rather than throwing (see lib/content/models/non_blank.dart and the
    // spec's "Carried forward from step 1"), so the strictness lives here.
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        final raw = lesson.raw;
        for (final key in ['titleAr', 'textAr', 'sourceText']) {
          final value = raw[key];
          if (value != null) {
            expect(value, isA<String>(), reason: '${lesson.id}.$key');
          }
        }
        for (final a in lesson.activities) {
          for (final key in [
            'promptAr',
            'textAr',
            'sourceText',
            'sourceCard',
          ]) {
            final value = a.raw[key];
            if (value != null) {
              expect(value, isA<String>(), reason: '${a.id}.$key');
            }
          }
        }
      }
    }
  });

  test('English fields contain no Arabic script', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        expect(_arabic.hasMatch(lesson.title), isFalse, reason: lesson.id);
        for (final a in lesson.activities) {
          // A matching activity legitimately pairs English with Arabic; its
          // prompt is still English.
          expect(_arabic.hasMatch(a.prompt), isFalse, reason: a.id);
        }
      }
    }
  });
}
