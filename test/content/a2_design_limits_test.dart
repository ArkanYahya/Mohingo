import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'a2_finished_units.dart';

/// The spec's length bands, by where the unit sits in the level.
({List<int> listening, List<int> reading, List<int> writing}) _bandsFor(
  String unitId,
) {
  final n = int.parse(unitId.split('-U').last);
  if (n <= 4) {
    return (listening: [30, 60], reading: [60, 100], writing: [55, 75]);
  }
  if (n <= 8) {
    return (listening: [50, 90], reading: [90, 140], writing: [65, 85]);
  }
  return (listening: [70, 120], reading: [120, 180], writing: [75, 100]);
}

int _words(String? s) => RegExp(r"[A-Za-z']+").allMatches(s ?? '').length;

void main() {
  test('each unit is in skill balance', () {
    for (final unit in finishedA2Units()) {
      final acts = activitiesOf(unit).toList();
      int n(Skill s) => acts.where((a) => a.skill == s).length;
      final speaking = n(Skill.spokenInteraction) + n(Skill.spokenProduction);
      expect(
        n(Skill.listening),
        greaterThanOrEqualTo(10),
        reason: '${unit.id} listening',
      );
      expect(
        n(Skill.reading),
        lessThanOrEqualTo(12),
        reason: '${unit.id} reading',
      );
      expect(speaking, inInclusiveRange(6, 8), reason: '${unit.id} speaking');
      expect(n(Skill.writing), 3, reason: '${unit.id} writing');
      expect(n(Skill.mediation), 2, reason: '${unit.id} mediation');
    }
  });

  test('every guided lesson opens on a real conversation', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        if (lesson.lessonType != 'encounter-focus-practice') continue;
        final lines = lesson.encounterDialogue;
        expect(
          lines.length,
          inInclusiveRange(4, 8),
          reason: '${lesson.id} lines',
        );
        final speakers = {for (final l in lines) l.speaker.trim()};
        expect(
          speakers.length,
          inInclusiveRange(2, 3),
          reason: '${lesson.id} speakers',
        );
      }
    }
  });

  test('each unit has one model text for its production lesson', () {
    for (final unit in finishedA2Units()) {
      final withText = unit.lessons
          .where((l) => l.readingText != null)
          .toList();
      expect(withText.length, 1, reason: '${unit.id} readingText count');
      expect(withText.single.lessonType, 'integrated-production');
    }
  });

  test('no prompt is used more than three times in a unit', () {
    for (final unit in finishedA2Units()) {
      final counts = <String, int>{};
      for (final a in activitiesOf(unit)) {
        final key = a.prompt.trim().toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
      final overused = counts.entries.where((e) => e.value > 3).toList();
      expect(
        overused,
        isEmpty,
        reason: '${unit.id}: ${overused.map((e) => '"${e.key}" x${e.value}')}',
      );
    }
  });

  test('at most one English-to-Arabic matching activity per unit', () {
    final arabic = RegExp(r'[؀-ۿ]');
    for (final unit in finishedA2Units()) {
      var translationMatches = 0;
      for (final a in activitiesOf(unit)) {
        if (a is! MatchActivity) continue;
        final pairs = a.raw['pairs'];
        if (pairs is! List || pairs.isEmpty) continue;
        // Count a pair as a translation if EITHER side carries Arabic
        // script. Reading only p[1] means moving the Arabic to the left of
        // each pair (English on the right) makes a real translation match
        // count as zero, letting a unit exceed the cap undetected.
        final looksLikeTranslation = pairs.every(
          (p) =>
              p is List &&
              p.length == 2 &&
              (arabic.hasMatch('${p[0]}') || arabic.hasMatch('${p[1]}')),
        );
        if (looksLikeTranslation) translationMatches++;
      }
      expect(translationMatches, lessThanOrEqualTo(1), reason: unit.id);
    }
  });

  test('every activity carries at least one canDo objective', () {
    // The category-check below iterates an activity's objectives, so
    // "canDo": [] passes it vacuously. An untagged activity is worse than
    // one tagged wrong: deleting a tag is the cheapest way to make that
    // gate green, and it can quietly drop a required objective below its
    // two carriers without any gate noticing.
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        expect(a.canDo, isNotEmpty, reason: '${a.id} carries no canDo tag');
      }
    }
  });

  test("an activity's canDo objectives match the skill it evidences", () {
    const categoryBySkill = {
      Skill.listening: 'LISTENING',
      Skill.reading: 'READING',
      Skill.writing: 'WRITING',
      Skill.spokenProduction: 'PRODUCTION',
      Skill.spokenInteraction: 'INTERACTION',
      Skill.mediation: 'MEDIATION',
    };
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        final expected = categoryBySkill[a.skill]!;
        for (final objective in a.canDo) {
          // A mission's ACTION.* objective accepts evidence from any skill.
          if (objective.contains('.ACTION.')) continue;
          expect(
            objective,
            contains('.$expected.'),
            reason: '${a.id} (${a.skill}) claims $objective',
          );
        }
      }
    }
  });

  test('listening input is inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).listening;
      for (final lesson in unit.lessons) {
        if (lesson.encounterDialogue.isNotEmpty) {
          final words = lesson.encounterDialogue
              .map((l) => _words(l.en))
              .fold<int>(0, (a, b) => a + b);
          expect(
            words,
            inInclusiveRange(band[0], band[1]),
            reason: '${lesson.id} conversation is $words words',
          );
        }
        for (final a in lesson.activities) {
          if (a.skill != Skill.listening) continue;
          final words = _words(a.raw['audioTranscript'] as String?);
          expect(
            words,
            inInclusiveRange(band[0], band[1]),
            reason: '${a.id} transcript is $words words',
          );
        }
      }
    }
  });

  test('the model text is inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).reading;
      for (final lesson in unit.lessons) {
        final text = lesson.readingText;
        if (text == null) continue;
        final words = _words(text.text);
        expect(
          words,
          inInclusiveRange(band[0], band[1]),
          reason: '${lesson.id} model text is $words words',
        );
      }
    }
  });

  test('notices and source cards are 15-60 words', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        for (final key in ['sourceText', 'sourceCard']) {
          final value = a.raw[key];
          if (value is! String || value.trim().isEmpty) continue;
          expect(
            _words(value),
            inInclusiveRange(15, 60),
            reason: '${a.id}.$key',
          );
        }
      }
    }
  });

  test('every writing task carries a wordGuide inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).writing;
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.writing) continue;
        final guide = a.raw['wordGuide'];
        expect(guide, isA<List>(), reason: '${a.id} has no wordGuide');
        final g = (guide as List).cast<num>();
        expect(g.length, 2, reason: '${a.id} wordGuide shape');
        expect(g[0], band[0], reason: '${a.id} wordGuide low');
        expect(g[1], band[1], reason: '${a.id} wordGuide high');
      }
    }
  });
}
