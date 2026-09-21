import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'level_gate_config.dart';

int _words(String? s) => RegExp(r"[A-Za-z']+").allMatches(s ?? '').length;

/// Ported from `a2_design_limits_test.dart`, which held these rules as
/// A2-specific code. Every number here now comes from the level's config.
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('each unit is in skill balance', () {
        for (final unit in gate.finishedUnits()) {
          final acts = activitiesOf(unit).toList();
          int n(Skill s) => acts.where((a) => a.skill == s).length;
          final speaking =
              n(Skill.spokenInteraction) + n(Skill.spokenProduction);
          final balance = gate.balanceFor(unit.id);
          final why = gate.why(unit.id);
          void inBand(String label, int count, Range band) {
            expect(
              band.contains(count),
              isTrue,
              reason: '${unit.id} $label is $count, outside $band$why',
            );
          }

          inBand('listening', n(Skill.listening), balance.listening);
          inBand('reading', n(Skill.reading), balance.reading);
          inBand('speaking', speaking, balance.speaking);
          inBand('writing', n(Skill.writing), balance.writing);
          inBand('mediation', n(Skill.mediation), balance.mediation);
        }
      });

      test('every guided lesson opens on a real conversation', () {
        for (final unit in gate.finishedUnits()) {
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
        for (final unit in gate.finishedUnits()) {
          if (!gate.requiresModelTextPerUnit) continue;
          if (gate.modelTextExceptions.containsKey(unit.id)) continue;
          final withText = unit.lessons
              .where((l) => l.readingText != null)
              .toList();
          expect(withText.length, 1, reason: '${unit.id} readingText count');
          expect(withText.single.lessonType, 'integrated-production');
        }
      });

      test('no prompt is repeated more often than the level allows, in '
          'either language', () {
        // The rule exists because the import used the same drill six times a
        // unit. Keyed on `prompt` alone it only ever enforced that in English:
        // one identical `promptAr` across all 36 activities of a unit passed —
        // against the app's primary audience, who read the Arabic first. Both
        // are counted, each in its own tally, because they are separately
        // authored strings and either can go stale on its own.
        for (final unit in gate.finishedUnits()) {
          final counts = <(String language, String prompt), int>{};
          for (final a in activitiesOf(unit)) {
            final en = ('prompt', a.prompt.trim().toLowerCase());
            counts[en] = (counts[en] ?? 0) + 1;
            final arabic = a.promptAr?.trim().toLowerCase() ?? '';
            if (arabic.isEmpty)
              continue; // a missing promptAr is the bilingual gate's
            final ar = ('promptAr', arabic);
            counts[ar] = (counts[ar] ?? 0) + 1;
          }
          final overused = counts.entries
              .where((e) => e.value > gate.maxPromptRepeatsPerUnit)
              .toList();
          expect(
            overused,
            isEmpty,
            reason:
                '${unit.id}: '
                '${overused.map((e) => '${e.key.$1} "${e.key.$2}" x${e.value}')}',
          );
        }
      });

      test('no more English-to-Arabic matching activities per unit than '
          'the level allows', () {
        final arabic = RegExp(r'[؀-ۿ]');
        for (final unit in gate.finishedUnits()) {
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
          expect(
            translationMatches,
            lessThanOrEqualTo(gate.maxEnglishToArabicMatchesPerUnit),
            reason: unit.id,
          );
        }
      });

      test('every activity carries at least one canDo objective', () {
        // The category-check below iterates an activity's objectives, so
        // "canDo": [] passes it vacuously. An untagged activity is worse than
        // one tagged wrong: deleting a tag is the cheapest way to make that
        // gate green, and it can quietly drop a required objective below its
        // two carriers without any gate noticing.
        for (final unit in gate.finishedUnits()) {
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
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            for (final a in lesson.activities) {
              if (gate.canDoTagging == CanDoTagging.perActivitySkill) {
                final expected = categoryBySkill[a.skill]!;
                for (final objective in a.canDo) {
                  // A mission's ACTION.* objective accepts evidence from
                  // any skill.
                  if (objective.contains('.ACTION.')) continue;
                  expect(
                    objective,
                    contains('.$expected.'),
                    reason: '${a.id} (${a.skill}) claims $objective',
                  );
                }
              } else {
                // This level tags activities with their lesson's whole
                // list, so an activity's objectives cannot be matched to
                // its own skill. The equivalent rule at lesson
                // granularity: an activity may only claim what its lesson
                // declares, and (below) every skill the lesson's
                // activities evidence must have an objective of its
                // category in that list. A mis-categorised lesson still
                // fails — this changes where the rule is applied, not how
                // strong it is.
                expect(
                  lesson.canDo,
                  containsAll(a.canDo),
                  reason:
                      '${a.id} claims an objective its lesson ${lesson.id} '
                      'does not declare',
                );
              }
            }
            if (gate.canDoTagging != CanDoTagging.lessonWide) continue;
            final declared = {
              for (final objective in lesson.canDo)
                for (final entry in categoryBySkill.entries)
                  if (objective.contains('.${entry.value}.')) entry.value,
            };
            for (final skill in {for (final a in lesson.activities) a.skill}) {
              expect(
                declared,
                contains(categoryBySkill[skill]!),
                reason:
                    '${lesson.id} has ${skill.name} activities but declares '
                    'no ${categoryBySkill[skill]} objective — a learner '
                    'evidences nothing by doing them',
              );
            }
          }
        }
      });

      test('listening input is inside its band', () {
        for (final unit in gate.finishedUnits()) {
          final band = gate.bandsFor(unit.id).listening;
          for (final lesson in unit.lessons) {
            if (lesson.encounterDialogue.isNotEmpty) {
              final words = lesson.encounterDialogue
                  .map((l) => _words(l.en))
                  .fold<int>(0, (a, b) => a + b);
              expect(
                words,
                inInclusiveRange(band.min, band.max),
                reason: '${lesson.id} conversation is $words words',
              );
            }
            for (final a in lesson.activities) {
              if (a.skill != Skill.listening) continue;
              final words = _words(a.raw['audioTranscript'] as String?);
              expect(
                words,
                inInclusiveRange(band.min, band.max),
                reason: '${a.id} transcript is $words words',
              );
            }
          }
        }
      });

      test('the model text is inside its band', () {
        for (final unit in gate.finishedUnits()) {
          final band = gate.bandsFor(unit.id).reading;
          for (final lesson in unit.lessons) {
            final text = lesson.readingText;
            if (text == null) continue;
            final words = _words(text.text);
            expect(
              words,
              inInclusiveRange(band.min, band.max),
              reason: '${lesson.id} model text is $words words',
            );
          }
        }
      });

      test('notices and source cards are 15-60 words', () {
        for (final unit in gate.finishedUnits()) {
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

      test('every free-writing task carries a wordGuide inside its '
          'band', () {
        // Keyed on WriteActivity, not on Skill.writing. A level can carry
        // writing-skill tasks that ask for no free text at all — A1 has 13
        // `order` tasks (put these sentences in order) and 3 `form` tasks
        // (fill these fields), and a word-count guide means nothing for
        // either. Keying on the skill would have reported 16 defects that
        // are not defects, which is the same "compare a cruder key than
        // the rule means" mistake this suite has made before.
        for (final unit in gate.finishedUnits()) {
          final band = gate.bandsFor(unit.id).writing;
          for (final a in activitiesOf(unit)) {
            if (a is! WriteActivity) continue;
            final guide = a.raw['wordGuide'];
            expect(guide, isA<List>(), reason: '${a.id} has no wordGuide');
            final g = (guide as List).cast<num>();
            expect(g.length, 2, reason: '${a.id} wordGuide shape');
            if (gate.wordGuideMustEqualBand) {
              // This level asks every writing task in a unit for the same
              // length, so the guide is the band.
              expect(g[0], band.min, reason: '${a.id} wordGuide low');
              expect(g[1], band.max, reason: '${a.id} wordGuide high');
            } else {
              // This level gives each task its own guide; it must still sit
              // inside the unit's band, and still be a real range.
              expect(
                g[0] < g[1],
                isTrue,
                reason: '${a.id} wordGuide $g is not a range',
              );
              expect(
                band.contains(g[0].toInt()) && band.contains(g[1].toInt()),
                isTrue,
                reason: '${a.id} wordGuide $g is outside $band',
              );
            }
          }
        }
      });

      test('each unit teaches enough new vocabulary', () {
        // The spec asks for "about 35 new senses per unit". The floor here is
        // 30, not 35: a hard floor a good unit can miss by one is a gate people
        // learn to work around, and 30 is the count below which a unit is
        // clearly under-taught. Every other gate in this suite counts
        // activities; nothing counted the words those activities are supposed
        // to teach, so a unit could grow to its full 36 activities while still
        // introducing a handful of senses.
        final minimumSenses = gate.minimumNewSensesPerUnit;
        for (final unit in gate.finishedUnits()) {
          final taught = <String>{
            for (final lesson in unit.lessons) ...[
              ...lesson.lexicon,
              ...lesson.chunks,
            ],
          };
          expect(
            taught.length,
            greaterThanOrEqualTo(minimumSenses),
            reason:
                '${unit.id} teaches ${taught.length} senses; a unit needs at '
                'least $minimumSenses',
          );
        }
      });
    });
  }
}
