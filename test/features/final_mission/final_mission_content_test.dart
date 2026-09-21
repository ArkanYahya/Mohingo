import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// The rubric of the three activity types that carry one.
EvaluationSpec? _evaluationOf(Activity activity) => switch (activity) {
  WriteActivity(:final evaluation) => evaluation,
  SpeakActivity(:final evaluation) => evaluation,
  FormActivity(:final evaluation) => evaluation,
  _ => null,
};

/// Every shipped level's final mission, by the code that names it.
final _missions = {
  for (final level in ['A1', 'A2'])
    level: CourseBundleParser.parse(
      File('assets/content/en/$level/${level.toLowerCase()}-course-bundle.json')
          .readAsStringSync(),
    ).finalMission,
};

void main() {
  group('a capstone promises only what it can deliver', () {
    for (final MapEntry(key: level, value: mission) in _missions.entries) {
      test('$level\'s final mission has no rubric waiting on an online '
          'check', () {
        // `onlineRefinement` makes an answer notAutoGraded and tells the
        // learner it will be checked once they are online — but only
        // LessonPlayerScreen enqueues the pending refinement that resolves
        // it. FinalMissionScreen does not, so such an answer would be
        // stored with isCorrect: null and never come back. A capstone
        // grades its answers itself.
        final waiting = [
          for (final activity in mission.activities)
            if (_evaluationOf(activity) case KeywordChecklistEvaluationSpec(
              onlineRefinement: final refinement?,
            ))
              '${activity.id} ($refinement)',
        ];
        expect(waiting, isEmpty);
      });
    }
  });
}
