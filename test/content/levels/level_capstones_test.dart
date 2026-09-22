import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/course_bundle.dart';

import 'level_capstone_checks.dart';
import 'level_gate_config.dart';

/// Content gates for each level's two capstones — its Final Mission and
/// its Final Assessment.
///
/// Every other gate in this directory walks `finishedUnits()`, which is
/// built from `bundle.units`. Neither capstone is a unit, so before this
/// file existed A2's twelve units were gated six ways and the two objects
/// a learner must actually clear to leave the level were gated not at all:
/// both were authored against these rules, verified by hand and by
/// throwaway tests, and then left with nothing to stop the next edit
/// undoing any of it.
///
/// The rules themselves live in `level_capstone_checks.dart` so that
/// `level_masterable_test.dart`'s release rule can re-run all of them the
/// day a level is marked `available`, instead of a second, drifting copy.
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      late CourseBundle bundle;

      setUpAll(() => bundle = gate.bundle());

      void expectNoViolations(List<String> violations) {
        expect(violations, isEmpty, reason: violations.join('\n'));
      }

      test('both capstones have content for every gate below to inspect', () {
        // Runs first for a reason: every gate in this file iterates the capstones
        // and reports what it finds wrong, so an empty mission or an empty
        // assessment section would turn the whole file green while asserting
        // nothing — the same failure mode `finishedUnits()` refuses for the
        // unit list.
        expectNoViolations(capstoneStructureViolations(bundle, gate));
      });

      test('every skill the exit requires is a section the exit contains', () {
        expectNoViolations(capstoneDecisionRuleViolations(bundle, gate));
      });

      test('every learner-facing capstone string carries Arabic', () {
        expectNoViolations(capstoneBilingualViolations(bundle, gate));
      });

      test('every capstone speak or write task carries a working grader', () {
        expectNoViolations(capstoneGraderViolations(bundle, gate));
      });

      test('every capstone task supplies what it asks the learner to work '
          'from', () {
        expectNoViolations(capstoneAnswerableViolations(bundle, gate));
      });

      test('capstone inputs and writing guides are inside their bands', () {
        expectNoViolations(capstoneLengthViolations(bundle, gate));
      });

      test('both exits of the level are marked to the same bar', () {
        expectNoViolations(capstonePassMarkViolations(bundle, gate));
      });

      test('no capstone input reuses text the learner has already met', () {
        expectNoViolations(capstoneUnseenInputViolations(bundle, gate));
      });
    });
  }
}
