import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'level_gate_config.dart';

/// Ported from `a2_answerable_test.dart`, which held these rules as
/// A2-specific code: can a learner actually answer what the content asks?
/// "A. / B." lists two whole phrases; "left/right" lists two words in one
/// slot. Anything else is a single phrase.
List<String> alternativesOf(String text) {
  if (text.contains(' / ')) return text.split(' / ');
  final slot = RegExp(r"([A-Za-z']+)/([A-Za-z']+)").firstMatch(text);
  if (slot == null) return [text];
  return [
    text.replaceRange(slot.start, slot.end, slot[1]!),
    text.replaceRange(slot.start, slot.end, slot[2]!),
  ];
}

void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('every mediation task supplies the material it asks about', () {
        for (final unit in gate.finishedUnits()) {
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
        for (final unit in gate.finishedUnits()) {
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
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            for (final a in lesson.activities) {
              if (a.skill != Skill.reading) continue;
              if (a is! TextChoiceActivity) continue;
              // A drill whose prompt carries its own material — "Complete:
              // I'm ___ Iraq.", "Reply naturally: Nice to meet you." — is
              // not asking about a text; a text for it would repeat the
              // prompt or give the answer away. The colon is the authored
              // convention for that. Measured before adopting it: no A2
              // reading item has one, so A2's protection is unchanged.
              if (a.prompt.contains(':')) continue;
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

      test('every closed question can be answered right, and can be answered '
          'wrong', () {
        // The gates above ask whether an item supplies its material. They never
        // look inside the options, and `ChoiceActivityView._submit` grades
        // `_selected == widget.answer` where `_selected` is always one of the
        // options — so an `answer` that is not among its own `options` makes
        // every attempt wrong, forever. On a mastery item carrying a required
        // objective that makes the whole unit permanently unmasterable, and it
        // is invisible to every other check in this file.
        //
        // The mirror image is just as broken and much easier to write by
        // accident: options that are all the same string, or a single option
        // that is the answer, are marked correct whatever the learner taps, so
        // the item produces mastery evidence for nothing. Both are one rule —
        // a closed question needs at least two distinct choices, exactly one
        // meaning of which is right.
        for (final unit in gate.finishedUnits()) {
          for (final a in activitiesOf(unit)) {
            final (List<String> options, String answer)? choice = switch (a) {
              TextChoiceActivity() => (a.options, a.answer),
              AudioChoiceActivity() => (a.options, a.answer),
              GapActivity() => (a.options, a.answer),
              _ => null,
            };
            if (choice != null) {
              final (options, answer) = choice;
              expect(
                options,
                contains(answer),
                reason:
                    '${a.id} answers "$answer", which is not one of its '
                    'options $options — every attempt is graded wrong',
              );
              expect(
                options.map((o) => o.trim()).toSet().length,
                greaterThanOrEqualTo(2),
                reason:
                    '${a.id} offers $options — with nothing to choose between, '
                    'any tap is marked correct',
              );
            }
            if (a is GapActivity) {
              // GapActivityView renders the sentence by splitting on `___`; a
              // text without one shows the learner a complete sentence and no
              // gap to fill.
              expect(
                a.text,
                contains('___'),
                reason: '${a.id} is a gap task whose text has no ___ gap in it',
              );
            }
            if (a is MatchActivity) {
              // One pair leaves the learner nothing to decide: the single left
              // item can only go with the single right one.
              expect(
                a.pairs.length,
                greaterThanOrEqualTo(2),
                reason:
                    '${a.id} is a matching task with ${a.pairs.length} pair(s) '
                    '— there is no choice to get wrong',
              );
              for (final pair in a.pairs) {
                expect(
                  pair.length,
                  2,
                  reason: '${a.id} has a pair that is not [left, right]: $pair',
                );
                for (final side in pair) {
                  expect(
                    side.trim(),
                    isNotEmpty,
                    reason: '${a.id} has a pair with a blank side: $pair',
                  );
                }
              }
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
        for (final unit in gate.finishedUnits()) {
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
            // Any spec the evaluator grades is structured. A2's productive
            // tasks are all keyword checklists, but "spell your name" is
            // graded letter by letter against the profile name
            // (letterSequence) and "how old are you" against a range
            // (numericRange) — rubrics a keyword list could not express.
            // What this gate refuses is the legacy list of rubric names no
            // grader reads; keying on one spec type refused the others too.
            const graded = {
              'keywordChecklist',
              'letterSequence',
              'numericRange',
              'nonEmpty',
            };
            expect(
              graded,
              contains(map['type']),
              reason: '${a.id} evaluation type ${map['type']} is not graded',
            );
            if (map['type'] != 'keywordChecklist') continue;
            final groups = map['requiredGroups'];
            expect(groups is List && groups.isNotEmpty, isTrue, reason: a.id);
            for (final group in groups as List) {
              expect(
                group is List && group.isNotEmpty,
                isTrue,
                reason: '${a.id} has an empty keyword group',
              );
            }
            final minGroupsMatched = map['minGroupsMatched'];
            expect(minGroupsMatched, isA<int>(), reason: a.id);
            final requiredMatches = minGroupsMatched as int;
            // minGroupsMatched: 0 satisfies a naive presence check while
            // evaluator.dart's _keywordChecklist marks every answer correct at
            // score 1.0 regardless of content (matchedGroups >= 0 is always
            // true) — worse than the legacy shape it replaced, which at least
            // left the task ungraded rather than grading it perfect.
            expect(
              requiredMatches,
              greaterThanOrEqualTo(1),
              reason:
                  '${a.id} has minGroupsMatched=$requiredMatches — the '
                  'evaluator marks every answer correct regardless of content',
            );
            // The opposite failure is equally broken: a rubric that demands
            // more groups than it contains can never be satisfied by any
            // answer.
            final groupCount = groups.length;
            expect(
              groupCount,
              greaterThanOrEqualTo(requiredMatches),
              reason:
                  '${a.id} requires $requiredMatches of only $groupCount '
                  'groups — this can never be satisfied',
            );

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
        for (final unit in gate.finishedUnits()) {
          for (final a in activitiesOf(unit)) {
            if (a.skill != Skill.spokenInteraction) continue;
            // Read the parsed accessor, not the raw field: SpeakActivity.
            // partnerTurns (which also covers A1's older examinerTurns) filters
            // out blank strings, so a raw list of empty strings — e.g.
            // ["", ""] — would satisfy a raw-field check while the app hands
            // the learner an interaction task with no partner turns at all.
            expect(
              a,
              isA<SpeakActivity>(),
              reason:
                  '${a.id} is a spokenInteraction task but not a '
                  'SpeakActivity',
            );
            final turns = (a as SpeakActivity).partnerTurns;
            expect(
              turns,
              isNotEmpty,
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
        // An activity's PROMPT is deliberately not part of the haystack. "Ask a
        // follow-up question" is an instruction, not the lesson teaching the
        // word in context, and counting it lets a unit claim vocabulary it only
        // ever names in its own rubric.
        final a2 = gate.bundle();
        final byId = {for (final l in a2.lexicon) l.id: l};
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            final haystack = [
              for (final line in lesson.encounterDialogue) line.en,
              lesson.readingText?.text ?? '',
              lesson.readingText?.title ?? '',
              for (final a in lesson.activities) ...[
                '${a.raw['partnerTurns'] ?? ''}',
                '${a.raw['text'] ?? ''}',
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

      test('every phrase a lesson lists actually appears in that lesson', () {
        // The companion of the vocabulary gate above, and it was left out on
        // purpose: chunk texts carry placeholders ("have ... in common",
        // "Could you tell me ...?"), and a literal match would fail correct
        // content, since the lesson fills the slot rather than printing the
        // ellipsis. That reasoning covers the 47 template chunks. It does not
        // cover the other 98, which are plain phrases — "Tell me more.",
        // "right now", "connect to Wi-Fi" — that either appear in their lesson
        // or do not, and 31 listings did not: a word the Words & phrases screen
        // says the learner has met, which the lesson never once used.
        //
        // So the check splits on the thing that actually differs. A chunk whose
        // text has a placeholder is a pattern with a slot the lesson fills, and
        // is skipped; a chunk without one is a fixed phrase, and has to be
        // there. Matching is on tokens rather than raw substrings, because
        // punctuation is not part of a phrase's identity — a lesson that says
        // "Tell me more about it." has used "Tell me more." — but nothing
        // looser than that: the phrase must appear as the registry spells it,
        // which is how the learner will meet it again in Words & phrases.
        //
        // As with the vocabulary gate, an activity's PROMPT is not part of the
        // haystack: "Ask a follow-up question" is an instruction, not the
        // lesson using the phrase.
        //
        // The one way out of this gate is to write an ellipsis into a fixed
        // phrase's registry text, which is deliberately not free: that text is
        // what the learner reads in Words & phrases, so the dodge is visible on
        // the screen the phrase is taught from.
        // Two notations for a slot: A2's ellipsis ("have ... in common") and
        // A1's braces ("My name is {name}."). Same concept — the lesson
        // fills the slot rather than printing it — so both are templates.
        // Recognising only one notation demanded A1's templates verbatim,
        // which no lesson could ever satisfy.
        final placeholder = RegExp(r'\.\.\.|…|\{[^}]*\}');
        final token = RegExp(r"[a-z0-9']+");
        String normalise(String value) =>
            token.allMatches(value.toLowerCase()).map((m) => m[0]!).join(' ');

        final byId = {for (final c in gate.bundle().chunks) c.id: c};
        final offenders = <String>[];
        var checked = 0;
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            final haystack = normalise(
              [
                for (final line in lesson.encounterDialogue) line.en,
                lesson.readingText?.text ?? '',
                lesson.readingText?.title ?? '',
                for (final a in lesson.activities) ...[
                  '${a.raw['partnerTurns'] ?? ''}',
                  '${a.raw['text'] ?? ''}',
                  '${a.raw['audioTranscript'] ?? ''}',
                  '${a.raw['sourceText'] ?? ''}',
                  '${a.raw['sourceCard'] ?? ''}',
                  '${a.raw['options'] ?? ''}',
                  '${a.raw['answer'] ?? ''}',
                  '${a.raw['pairs'] ?? ''}',
                ],
              ].join(' '),
            );
            for (final id in lesson.chunks) {
              final chunk = byId[id];
              if (chunk == null) continue; // an A1 reference, as above
              if (placeholder.hasMatch(chunk.text)) continue;
              checked++;
              // A1 writes some phrase cards as alternatives — "Yes, I can.
              // / No, I can't.", "It's on your left/right." — and A2
              // writes none that way. Normalised whole, such a card became
              // one token run no lesson could contain. Each alternative
              // is required: the card teaches both, so a lesson that shows
              // one has not taught the phrase as the card presents it.
              for (final alternative in alternativesOf(chunk.text)) {
                if (!haystack.contains(normalise(alternative))) {
                  offenders.add(
                    '${lesson.id} lists "${chunk.text}" ($id) but never '
                    'uses "$alternative"',
                  );
                }
              }
            }
          }
        }
        expect(
          checked,
          greaterThan(0),
          reason: 'no fixed-phrase chunk listings were checked at all',
        );
        expect(offenders, isEmpty, reason: offenders.join('\n'));
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
        // A level that builds on nothing has no earlier senses to
        // re-register, so there is nothing here to check — and reaching
        // for a prerequisite that does not exist is what this used to do.
        final earlier = prerequisiteBundleOf(gate);
        if (earlier == null) return;
        final a1Senses = {
          for (final l in earlier.lexicon)
            '${l.headword.toLowerCase().trim()}|${l.partOfSpeech.toLowerCase().trim()}',
        };
        final byId = {for (final l in gate.bundle().lexicon) l.id: l};
        final offenders = <String>[];
        for (final unit in gate.finishedUnits()) {
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
    });
  }
}
