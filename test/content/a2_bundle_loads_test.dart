import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// The shipped A2 bundle must parse and index with the same reader A1 uses —
/// the acceptance test the curriculum package's own handover asks for. Its
/// lessons are not rewritten yet (see the A2 design doc's steps 4-5); this
/// only proves the app can load what was imported.
void main() {
  test(
    'the shipped A2 bundle parses, indexes and resolves every reference',
    () {
      final json = File('assets/content/en/A2/a2-course-bundle.json')
          .readAsStringSync();

      final index = CourseContentIndex.build(CourseBundleParser.parse(json));

      expect(index.bundle.course.id, 'EN-A2-V1');
      expect(index.unitsById, hasLength(12));
      expect(index.lessonsById, hasLength(84));
      expect(index.bundle.finalMission.id, 'A2-FINAL-MISSION');
      expect(index.bundle.finalAssessment.id, 'A2-FINAL-ASSESSMENT');
      expect(index.unitsById['A2-U1']!.lessons, hasLength(7));
    },
  );

  test('every A2 unit counts towards its level', () {
    final json = File('assets/content/en/A2/a2-course-bundle.json')
        .readAsStringSync();
    final bundle = CourseBundleParser.parse(json);

    expect(bundle.units.every((u) => u.countsTowardLevelMastery), isTrue);
  });
}
