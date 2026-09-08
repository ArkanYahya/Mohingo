import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

void main() {
  test('A1-U5-L6-A05 (the u5-free-time-message-rubric activity) is migrated '
      'to a keywordChecklist spec with online refinement enabled', () {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final activity =
        index.lessonsById['A1-U5-L6']!.activities.last as WriteActivity;

    expect(activity.id, 'A1-U5-L6-A05');
    final spec = activity.evaluation as KeywordChecklistEvaluationSpec;
    expect(spec.onlineRefinement, 'grammarCheck');
    expect(spec.minGroupsMatched, greaterThan(0));
    expect(spec.requiredGroups, isNotEmpty);
  });
}
