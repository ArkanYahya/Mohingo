import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'a2_finished_units.dart';

void main() {
  test('every mediation task supplies the material it asks about', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.mediation) continue;
        expect(
          a.sourceCard?.trim() ?? '',
          isNotEmpty,
          reason: '${a.id} asks the learner to relay nothing',
        );
      }
    }
  });

  test('every listening activity has a transcript to speak', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.listening) continue;
        final transcript = a.raw['audioTranscript'];
        expect(
          transcript is String && transcript.trim().isNotEmpty,
          isTrue,
          reason: a.id,
        );
      }
    }
  });

  test('every reading comprehension question supplies its text', () {
    // Only comprehension items need a text supplied to them. A gap, a match
    // and an order activity carry their own material in the prompt, the
    // pairs or the words to arrange — demanding a source card for those
    // would force a pointless one onto every grammar drill.
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final a in lesson.activities) {
          if (a.skill != Skill.reading) continue;
          if (a is! TextChoiceActivity) continue;
          final hasOwnText =
              (a.raw['sourceText'] as String?)?.trim().isNotEmpty ?? false;
          final hasCard = a.sourceCard != null;
          final hasLessonText =
              (lesson.readingText?.text.trim().isNotEmpty) ?? false;
          expect(
            hasOwnText || hasCard || hasLessonText,
            isTrue,
            reason: '${a.id} asks about a text the learner was never given',
          );
        }
      }
    }
  });

  test('every mastery speak or write task carries a STRUCTURED evaluation', () {
    // Presence is not enough. The A2 import carries A1's retired legacy
    // shape — an opaque list of rubric names, e.g.
    //   "evaluation": ["taskCompletion", "intelligibility", "accuracy"]
    // — which no grader reads. A1 was migrated off that to structured specs
    // (see DATA_MODEL.md's history); A2 must be authored with them.
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        final isProductive = a is SpeakActivity || a is WriteActivity;
        if (!isProductive || a.mode != ActivityMode.mastery) continue;
        final spec = a.raw['evaluation'];
        expect(
          spec,
          isA<Map>(),
          reason: '${a.id} still has the legacy rubric-name evaluation',
        );
        final map = spec as Map;
        expect(map['type'], 'keywordChecklist', reason: a.id);
        final groups = map['requiredGroups'];
        expect(groups is List && groups.isNotEmpty, isTrue, reason: a.id);
        for (final group in groups as List) {
          expect(
            group is List && group.isNotEmpty,
            isTrue,
            reason: '${a.id} has an empty keyword group',
          );
        }
        expect(map['minGroupsMatched'], isA<int>(), reason: a.id);

        // The raw-shape checks above inspect the JSON; this inspects what
        // the app actually gets. The parser drops a malformed spec to null
        // rather than throwing (see EvaluationSpec.fromJson), so a task can
        // carry an "evaluation" field and still reach the app ungradeable.
        // Today all 120 A2 speak/write activities do — none carry a
        // structured spec, so every one parses to null.
        final parsed = a is SpeakActivity
            ? a.evaluation
            : (a as WriteActivity).evaluation;
        expect(
          parsed,
          isNotNull,
          reason: '${a.id} reaches the app with no grader',
        );
      }
    }
  });

  test('every interaction task gives the learner something to reply to', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.spokenInteraction) continue;
        final turns = a.raw['partnerTurns'] ?? a.raw['examinerTurns'];
        expect(
          turns is List && turns.isNotEmpty,
          isTrue,
          reason: '${a.id} is an interaction with no partner',
        );
      }
    }
  });

  test('every word a lesson lists actually appears in that lesson', () {
    // The spec's rule: "Every listed word appears in its lesson's
    // conversation or text and is practised in at least one activity."
    // Only A2 records are checked — an A1 reference is revision, and the
    // lesson may legitimately only allude to it.
    final a2 = loadA2Bundle();
    final byId = {for (final l in a2.lexicon) l.id: l};
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        final haystack = [
          for (final line in lesson.encounterDialogue) line.en,
          lesson.readingText?.text ?? '',
          for (final a in lesson.activities) ...[
            a.prompt,
            '${a.raw['audioTranscript'] ?? ''}',
            '${a.raw['sourceText'] ?? ''}',
            '${a.raw['sourceCard'] ?? ''}',
            '${a.raw['options'] ?? ''}',
            '${a.raw['answer'] ?? ''}',
            '${a.raw['pairs'] ?? ''}',
          ],
        ].join(' ').toLowerCase();
        for (final id in lesson.lexicon) {
          final item = byId[id];
          if (item == null) continue; // an A1 reference
          expect(
            haystack,
            contains(item.headword.toLowerCase()),
            reason:
                '${lesson.id} lists ${item.headword} ($id) but never '
                'uses it',
          );
        }
      }
    }
  });

  test('no A1 sense is re-registered by a finished unit', () {
    // The brief's original version of this gate walked the entire A2
    // lexicon — all 216 records, including the eleven units nobody has
    // authored yet — which would fail on records outside a finished-units
    // gate's business. Scoped instead to what the finished units actually
    // reference, per the correction on this task.
    //
    // Matching on headword alone gives a false positive that can never be
    // fixed: A1's "change" is only ever a verb, while A2 registers "change"
    // as a noun (a genuinely new sense, exactly the case this gate's reason
    // text carves out). Match on headword AND partOfSpeech so a new sense
    // of an old word is never mistaken for a duplicate.
    final a1Senses = {
      for (final l in loadA1Bundle().lexicon)
        '${l.headword.toLowerCase().trim()}|${l.partOfSpeech.toLowerCase().trim()}',
    };
    final byId = {for (final l in loadA2Bundle().lexicon) l.id: l};
    final offenders = <String>[];
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final id in lesson.lexicon) {
          final item = byId[id];
          if (item == null) continue; // an A1 reference, which is the point
          final sense =
              '${item.headword.toLowerCase().trim()}|${item.partOfSpeech.toLowerCase().trim()}';
          if (a1Senses.contains(sense)) {
            offenders.add('${lesson.id} -> $id (${item.headword})');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'these A2 records repeat an A1 headword — reference the A1 '
          'record from the lesson instead, unless the sense is genuinely '
          'new (A1 "order" = a request, A2 "order" = a sequence)',
    );
  });
}
