import 'dart:io';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// The A2 units that claim to be finished content, not imported skeleton.
///
/// Every `test/content/a2_*` gate runs over exactly this list. A unit joins
/// it in the batch that authors it — never before — and A2 cannot be marked
/// available in the catalogue until all twelve are here (see
/// `a2_masterable_test.dart`'s release rule).
const a2FinishedUnitIds = <String>['A2-U1'];

CourseBundle loadA2Bundle() => CourseBundleParser.parse(
  File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
);

CourseBundle loadA1Bundle() => CourseBundleParser.parse(
  File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
);

List<Unit> finishedA2Units() {
  final byId = {for (final u in loadA2Bundle().units) u.id: u};
  return [
    for (final id in a2FinishedUnitIds)
      byId[id] ??
          (throw StateError(
            'a2FinishedUnitIds names $id, which the bundle '
            'does not contain',
          )),
  ];
}

Iterable<Activity> activitiesOf(Unit unit) =>
    unit.lessons.expand((l) => l.activities);
