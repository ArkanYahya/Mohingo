import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'level_gate_config.dart';

/// Ported from `a2_structure_test.dart` and `a2_bundle_loads_test.dart`,
/// which held these rules as A2-specific code. "No id is shared between
/// two levels" moved to `level_config_test.dart`, where it runs over every
/// pair rather than one.
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('the finished list is not empty', () {
        // Every other gate in this directory iterates that list. An empty
        // list would make all of them pass while asserting nothing.
        expect(gate.finishedUnitIds, isNotEmpty);
      });

      test('each finished unit has the shape its level declares', () {
        for (final unit in gate.finishedUnits()) {
          final shape = gate.shapeFor(unit.id);
          final why = gate.why(unit.id);
          expect(
            unit.lessons.length,
            shape.lessons,
            reason: '${unit.id} lessons$why',
          );
          final acts = activitiesOf(unit).toList();
          expect(
            acts.length,
            shape.activities,
            reason: '${unit.id} activities$why',
          );
          int count(ActivityMode m) => acts.where((a) => a.mode == m).length;
          expect(
            count(ActivityMode.encounter),
            shape.encounter,
            reason: '${unit.id} encounter$why',
          );
          expect(
            count(ActivityMode.practice),
            shape.practice,
            reason: '${unit.id} practice$why',
          );
          expect(
            count(ActivityMode.mastery),
            shape.mastery,
            reason: '${unit.id} mastery$why',
          );
        }
      });

      test('every grammar reference resolves in this level or the one it '
          'builds on, and every word and phrase in this level alone', () {
        // The self-containment rule, as decided: a level registers its own
        // vocabulary (a word listed from an earlier level would split that
        // word's review history across two ids), but may revise an earlier
        // level's grammar by referencing its record rather than duplicating
        // it. A2 lists no A1 id of any kind, so this changes no outcome
        // today; it stops the next level from quietly doing either the
        // wrong way round.
        final bundle = gate.bundle();
        final prerequisite = prerequisiteBundleOf(gate);
        final ownWords = {
          ...bundle.lexicon.map((l) => l.id),
          ...bundle.chunks.map((c) => c.id),
        };
        final grammar = {
          ...bundle.grammar.map((g) => g.id),
          if (prerequisite != null) ...prerequisite.grammar.map((g) => g.id),
        };
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            for (final id in lesson.grammar) {
              expect(
                grammar,
                contains(id),
                reason: '${lesson.id} references grammar $id',
              );
            }
            for (final id in [...lesson.lexicon, ...lesson.chunks]) {
              expect(
                ownWords,
                contains(id),
                reason:
                    '${lesson.id} lists $id, which is not one of '
                    "${gate.levelId}'s own words or phrases — a level "
                    'registers its own vocabulary',
              );
            }
          }
        }
      });

      test('the shipped bundle parses, indexes and resolves every '
          'reference', () {
        final index = CourseContentIndex.build(gate.bundle());

        expect(index.bundle.course.id, gate.courseId);
        expect(index.unitsById, hasLength(gate.finishedUnitIds.length));
        expect(
          index.lessonsById,
          hasLength(
            gate.finishedUnits().fold<int>(0, (n, u) => n + u.lessons.length),
          ),
        );
        expect(index.bundle.finalMission.id, gate.finalMissionId);
        expect(index.bundle.finalAssessment.id, gate.finalAssessmentId);
      });

      test('every unit that is not a prerequisite counts towards its '
          'level', () {
        // Keyed on the bundle's own levelRole rather than on a hand-listed
        // exception. A1-U0 is levelRole "prerequisite" — onboarding that
        // deliberately does not count towards A1 mastery — and a level may
        // legitimately have such a unit. What must never happen is a
        // "core" unit that counts towards nothing.
        for (final unit in gate.bundle().units) {
          if (unit.levelRole == 'prerequisite') {
            expect(
              unit.countsTowardLevelMastery,
              isFalse,
              reason:
                  '${unit.id} is a prerequisite unit but counts towards '
                  'level mastery',
            );
            continue;
          }
          expect(
            unit.countsTowardLevelMastery,
            isTrue,
            reason: '${unit.id} (${unit.levelRole}) counts towards nothing',
          );
        }
      });
    });
  }
}
