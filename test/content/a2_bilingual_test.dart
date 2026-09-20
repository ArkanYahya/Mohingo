import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/exceptions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

import 'a2_finished_units.dart';

final _arabic = RegExp(r'[؀-ۿ]');

/// The first activity object anywhere in the bundle JSON, walked in
/// document order. Used to exercise the parser's own field-level
/// validation directly, independent of [a2FinishedUnitIds].
Map<String, dynamic> _firstActivity(Map<String, dynamic> bundleJson) {
  for (final unit in bundleJson['units'] as List) {
    for (final lesson in (unit as Map<String, dynamic>)['lessons'] as List) {
      final activities = (lesson as Map<String, dynamic>)['activities'] as List;
      if (activities.isNotEmpty) {
        return activities.first as Map<String, dynamic>;
      }
    }
  }
  throw StateError('no activity found in the A2 bundle');
}

/// The first `encounter.dialogue` line anywhere in the bundle JSON, walked
/// in document order. Same rationale as [_firstActivity].
Map<String, dynamic> _firstDialogueLine(Map<String, dynamic> bundleJson) {
  for (final unit in bundleJson['units'] as List) {
    for (final lesson in (unit as Map<String, dynamic>)['lessons'] as List) {
      final encounter =
          (lesson as Map<String, dynamic>)['encounter']
              as Map<String, dynamic>?;
      final dialogue = encounter?['dialogue'] as List?;
      if (dialogue != null && dialogue.isNotEmpty) {
        return dialogue.first as Map<String, dynamic>;
      }
    }
  }
  throw StateError('no dialogue line found in the A2 bundle');
}

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

  test(
    'a bilingual field the parser silently drops must be a String when present',
    () {
      // sourceText, sourceCard and readingText.textAr all go through
      // nonBlank() (lib/content/models/non_blank.dart): a non-String value
      // is degraded to null rather than rejected, so the strictness the
      // spec asks for has to live here, not in the parser.
      //
      // promptAr and titleAr are deliberately NOT checked here — the
      // parser hard-casts both (`as String?` / `as String`), so a
      // non-String value there throws ContentParseException during
      // parsing itself, before finishedA2Units() ever returns. That
      // guarantee is asserted directly below.
      for (final unit in finishedA2Units()) {
        for (final lesson in unit.lessons) {
          final readingText =
              lesson.raw['readingText'] as Map<String, dynamic>?;
          final readingTextAr = readingText?['textAr'];
          if (readingTextAr != null) {
            expect(
              readingTextAr,
              isA<String>(),
              reason: '${lesson.id}.readingText.textAr',
            );
          }
          for (final a in lesson.activities) {
            for (final key in ['sourceText', 'sourceCard']) {
              final value = a.raw[key];
              if (value != null) {
                expect(value, isA<String>(), reason: '${a.id}.$key');
              }
            }
          }
        }
      }
    },
  );

  test('a bilingual field the parser hard-casts refuses to load rather than '
      'degrading silently', () {
    final rawJson = File('assets/content/en/A2/a2-course-bundle.json')
        .readAsStringSync();

    // Case 1: an activity's promptAr (`json['promptAr'] as String?`).
    final withBadPromptAr = jsonDecode(rawJson) as Map<String, dynamic>;
    _firstActivity(withBadPromptAr)['promptAr'] = 42;
    expect(
      () => CourseBundleParser.parse(jsonEncode(withBadPromptAr)),
      throwsA(isA<ContentParseException>()),
      reason: 'a non-String promptAr must fail to load, not parse as null',
    );

    // Case 2: a dialogue line's ar (`json['ar'] as String`).
    final withBadDialogueAr = jsonDecode(rawJson) as Map<String, dynamic>;
    _firstDialogueLine(withBadDialogueAr)['ar'] = 42;
    expect(
      () => CourseBundleParser.parse(jsonEncode(withBadDialogueAr)),
      throwsA(isA<ContentParseException>()),
      reason: 'a non-String dialogue ar must fail to load, not crash raw',
    );
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
