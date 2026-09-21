import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/course_bundle.dart';

import 'a2_capstone_checks.dart';
import 'a2_finished_units.dart';

/// Content gates for A2's two capstones — `A2-FINAL-MISSION` ("Host a
/// Visitor") and `A2-FINAL-ASSESSMENT`.
///
/// Every other `test/content/a2_*` gate walks `finishedA2Units()`, which is
/// built from `bundle.units`. Neither capstone is a unit, so until this file
/// existed the twelve units were gated six ways and the two objects a learner
/// must actually clear to leave A2 were gated not at all: both were authored
/// against these rules, verified by hand and by throwaway tests, and then left
/// with nothing to stop the next edit undoing any of it.
///
/// The rules themselves live in `a2_capstone_checks.dart` so that
/// `a2_masterable_test.dart`'s release rule can re-run all of them the day A2
/// is marked `available`, instead of a second, drifting copy.
void main() {
  late CourseBundle bundle;

  setUpAll(() => bundle = loadA2Bundle());

  void expectNoViolations(List<String> violations) {
    expect(violations, isEmpty, reason: violations.join('\n'));
  }

  test('both capstones have content for every gate below to inspect', () {
    // Runs first for a reason: every gate in this file iterates the capstones
    // and reports what it finds wrong, so an empty mission or an empty
    // assessment section would turn the whole file green while asserting
    // nothing — the same failure mode `finishedA2Units()` refuses for the
    // unit list.
    expectNoViolations(capstoneStructureViolations(bundle));
  });

  test('every learner-facing capstone string carries Arabic', () {
    expectNoViolations(capstoneBilingualViolations(bundle));
  });

  test('every capstone speak or write task carries a working grader', () {
    expectNoViolations(capstoneGraderViolations(bundle));
  });

  test('every capstone task supplies what it asks the learner to work '
      'from', () {
    expectNoViolations(capstoneAnswerableViolations(bundle));
  });

  test('capstone inputs and writing guides are inside their bands', () {
    expectNoViolations(capstoneLengthViolations(bundle));
  });

  test('both A2 exits are marked to the same bar, and that bar is A1\'s', () {
    expectNoViolations(capstonePassMarkViolations(bundle));
  });

  test('no capstone input reuses text the learner has already met', () {
    expectNoViolations(capstoneUnseenInputViolations(bundle));
  });
}
