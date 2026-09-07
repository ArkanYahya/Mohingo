import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_spec.dart';

void main() {
  group('WriteActivity.evaluation', () {
    test('WriteActivity parses a structured evaluation spec', () {
      final activity = Activity.fromJson({
        'id': 'A1-TEST-A01',
        'lessonId': 'A1-TEST-L1',
        'type': 'write',
        'mode': 'mastery',
        'skill': 'writing',
        'canDo': <String>[],
        'prompt': 'Write your name.',
        'accepted': <String>[],
        'evaluation': {'type': 'nonEmpty'},
      }) as WriteActivity;

      expect(activity.evaluation, isA<NonEmptyEvaluationSpec>());
    });

    test('WriteActivity with a not-yet-migrated legacy evaluation string '
        'parses evaluation as null, not a crash', () {
      final activity = Activity.fromJson({
        'id': 'A1-TEST-A02',
        'lessonId': 'A1-TEST-L1',
        'type': 'write',
        'mode': 'mastery',
        'skill': 'writing',
        'canDo': <String>[],
        'prompt': 'Write a message.',
        'accepted': <String>[],
        'evaluation': 'some-legacy-rubric-name',
      }) as WriteActivity;

      expect(activity.evaluation, isNull);
    });
  });
}
