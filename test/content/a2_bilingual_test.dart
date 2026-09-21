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
          final ar = line.ar.trim();
          expect(
            ar,
            isNotEmpty,
            reason: '${lesson.id} line by ${line.speaker}',
          );
          // Non-empty is not enough — the cheapest way to pass a bilingual
          // gate is to copy the English string into `ar`. Require actual
          // Arabic script, which that copy would never contain.
          expect(
            _arabic.hasMatch(ar),
            isTrue,
            reason:
                '${lesson.id} line by ${line.speaker} has no Arabic '
                'script: "$ar"',
          );
        }
      }
    }
  });

  test('every activity prompt carries Arabic', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        final ar = a.promptAr?.trim() ?? '';
        expect(ar, isNotEmpty, reason: a.id);
        expect(
          _arabic.hasMatch(ar),
          isTrue,
          reason: '${a.id} promptAr has no Arabic script: "$ar"',
        );
      }
    }
  });

  test('a lesson with a model text carries its Arabic', () {
    // readingText.textAr goes through nonBlank(), so textAr: "" parses to
    // null exactly like a missing field — the review found it would pass
    // every other gate while turning a bilingual model text into an
    // English-only one.
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        final readingText = lesson.readingText;
        if (readingText == null) continue;
        final ar = readingText.textAr?.trim() ?? '';
        expect(ar, isNotEmpty, reason: '${lesson.id}.readingText.textAr');
        expect(
          _arabic.hasMatch(ar),
          isTrue,
          reason: '${lesson.id}.readingText.textAr has no Arabic script: "$ar"',
        );
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

  test('every word, phrase and structure a unit teaches carries Arabic', () {
    // The gates above read what a learner meets inside a lesson. They never
    // read the registries — and Vocabulary, Grammar and Review are built
    // from nothing else. `lexicon.arabic`, `grammar.meaningAr` and
    // `chunk.arabic` are the only Arabic those screens have: blank them, or
    // copy the English across, and the whole of Words & phrases and Grammar
    // goes monolingual for an Arabic-speaking learner while this suite
    // stays green. That is the app's first non-negotiable rule, and until
    // now no test in this directory touched any of the three fields.
    //
    // Records are resolved against A1's bundle as well as A2's, because an
    // A2 lesson may legitimately list an A1 word for revision and the
    // learner sees that record exactly as they see an A2 one. An id that
    // resolves in neither is reported here too rather than skipped: it is
    // a word the lesson claims to teach and the app cannot show at all.
    final a2 = loadA2Bundle();
    final a1 = loadA1Bundle();
    final lexicon = {
      for (final l in [...a1.lexicon, ...a2.lexicon]) l.id: l.arabic,
    };
    final grammar = {
      for (final g in [...a1.grammar, ...a2.grammar]) g.id: g.meaningAr,
    };
    final chunks = {
      for (final c in [...a1.chunks, ...a2.chunks]) c.id: c.arabic,
    };

    final offenders = <String>[];
    var checked = 0;
    void check(
      String where,
      String field,
      Map<String, String> registry,
      String id,
    ) {
      checked++;
      final arabic = registry[id];
      if (arabic == null) {
        offenders.add('$where lists $id, which no bundle defines');
        return;
      }
      if (arabic.trim().isEmpty) {
        offenders.add('$where lists $id, whose $field is blank');
        return;
      }
      if (!_arabic.hasMatch(arabic)) {
        // Copying the English across is the cheapest way to pass a
        // presence check and the exact failure this rules out.
        offenders.add(
          '$where lists $id, whose $field has no Arabic script: '
          '"$arabic"',
        );
      }
    }

    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final id in lesson.lexicon) {
          check(lesson.id, 'lexicon.arabic', lexicon, id);
        }
        for (final id in lesson.grammar) {
          check(lesson.id, 'grammar.meaningAr', grammar, id);
        }
        for (final id in lesson.chunks) {
          check(lesson.id, 'chunk.arabic', chunks, id);
        }
      }
    }
    expect(
      checked,
      greaterThan(0),
      reason: 'no registry references were checked at all',
    );
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('every unit and lesson title carries Arabic', () {
    // The capstone gates read both capstone titles; nothing read a unit's
    // or a lesson's. They are the headings on the Learn tab and at the top
    // of every lesson, so an English-only one is the first thing a learner
    // sees — which made the omission an inconsistency rather than a
    // considered scope line.
    for (final unit in finishedA2Units()) {
      final unitAr = unit.titleAr.trim();
      expect(unitAr, isNotEmpty, reason: '${unit.id}.titleAr is missing');
      expect(
        _arabic.hasMatch(unitAr),
        isTrue,
        reason: '${unit.id}.titleAr has no Arabic script: "$unitAr"',
      );
      for (final lesson in unit.lessons) {
        final lessonAr = lesson.titleAr.trim();
        expect(lessonAr, isNotEmpty, reason: '${lesson.id}.titleAr is missing');
        expect(
          _arabic.hasMatch(lessonAr),
          isTrue,
          reason: '${lesson.id}.titleAr has no Arabic script: "$lessonAr"',
        );
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
