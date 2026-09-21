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

      test('every grammar, lexicon and chunk reference resolves in this '
          'level or the one it builds on', () {
        final bundle = gate.bundle();
        final prerequisite = prerequisiteBundleOf(gate);
        final known = {
          ...bundle.grammar.map((g) => g.id),
          ...bundle.lexicon.map((l) => l.id),
          ...bundle.chunks.map((c) => c.id),
          if (prerequisite != null) ...[
            ...prerequisite.grammar.map((g) => g.id),
            ...prerequisite.lexicon.map((l) => l.id),
            ...prerequisite.chunks.map((c) => c.id),
          ],
        };
        for (final unit in gate.finishedUnits()) {
          for (final lesson in unit.lessons) {
            for (final id in [
              ...lesson.grammar,
              ...lesson.lexicon,
              ...lesson.chunks,
            ]) {
              expect(
                known,
                contains(id),
                reason: '${lesson.id} references $id',
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

      test('every unit counts towards its level', () {
        expect(
          gate.bundle().units.every((u) => u.countsTowardLevelMastery),
          isTrue,
        );
      });
    });
  }
}
