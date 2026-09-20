import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'a2_finished_units.dart';

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
        final looksLikeTranslation = pairs.every(
          (p) => p is List && p.length == 2 && arabic.hasMatch('${p[1]}'),
        );
        if (looksLikeTranslation) translationMatches++;
      }
      expect(translationMatches, lessThanOrEqualTo(1), reason: unit.id);
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
}
