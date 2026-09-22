import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/domain/content_drift.dart';

ContentVersion _snapshot({
  List<String> activityIds = const [],
  List<String> canDoIds = const [],
}) => ContentVersion(
  id: 1,
  contentVersion: 'EN-A2-V1',
  schemaVersion: '2.0.0',
  courseId: 'EN-A2-V1',
  installedAt: DateTime.utc(2026, 9, 1),
  unitIdsJson: jsonEncode(const <String>[]),
  lessonIdsJson: jsonEncode(const <String>[]),
  activityIdsJson: jsonEncode(activityIds),
  canDoIdsJson: jsonEncode(canDoIds),
);

void main() {
  test('an unchanged bundle drifts in no way at all', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A', 'B'], canDoIds: ['X']),
      currentActivityIds: {'A', 'B'},
      currentCanDoIds: {'X'},
    );

    expect(drift.isEmpty, isTrue);
  });

  test('content that only grows is not drift — added activities and '
      'objectives are a normal content update', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A'], canDoIds: ['X']),
      currentActivityIds: {'A', 'B'},
      currentCanDoIds: {'X', 'Y'},
    );

    expect(drift.removedActivityIds, isEmpty);
    expect(drift.removedCanDoIds, isEmpty);
    expect(drift.addedCanDoIds, {'Y'});
  });

  test('a removed activity and a removed objective are both drift', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A', 'B'], canDoIds: ['X', 'Y']),
      currentActivityIds: {'A'},
      currentCanDoIds: {'X'},
    );

    expect(drift.removedActivityIds, {'B'});
    expect(drift.removedCanDoIds, {'Y'});
    expect(drift.isEmpty, isFalse);
  });

  test('only a unit the learner actually attempted goes stale', () {
    final stale = staleUnitIds(
      drift: const ContentDrift(
        removedActivityIds: {'A2-U1-L1-A01', 'A2-U5-L1-A01'},
        removedCanDoIds: {},
        addedCanDoIds: {},
      ),
      attemptedLessonByActivityId: const {'A2-U1-L1-A01': 'A2-U1-L1'},
      unitIdByLessonId: const {'A2-U1-L1': 'A2-U1', 'A2-U5-L1': 'A2-U5'},
      requiredObjectivesByUnitId: const {},
    );

    // U5's activity vanished too, but the learner never answered it, so
    // nothing of theirs is stranded and there is nothing to tell them.
    expect(stale, {'A2-U1'});
  });

  test('an answer recorded against no lesson strands nothing a unit row '
      'could say', () {
    // A capstone task, or an activity answered in a review session, records
    // no lesson — so there is no unit to place it in. Losing one must not
    // crash, and must not flag an unrelated unit either.
    final stale = staleUnitIds(
      drift: const ContentDrift(
        removedActivityIds: {'A2-FINAL-MISSION-A02'},
        removedCanDoIds: {},
        addedCanDoIds: {},
      ),
      attemptedLessonByActivityId: const {'A2-FINAL-MISSION-A02': null},
      unitIdByLessonId: const {'A2-U1-L1': 'A2-U1'},
      requiredObjectivesByUnitId: const {},
    );

    expect(stale, isEmpty);
  });

  test('a removed activity whose lesson was removed too flags nothing', () {
    // Nothing dishonest to say: the lesson it lived in is gone from the
    // bundle, so there is no unit row we can place their answer under.
    final stale = staleUnitIds(
      drift: const ContentDrift(
        removedActivityIds: {'A2-U1-L9-A01'},
        removedCanDoIds: {},
        addedCanDoIds: {},
      ),
      attemptedLessonByActivityId: const {'A2-U1-L9-A01': 'A2-U1-L9'},
      unitIdByLessonId: const {'A2-U1-L1': 'A2-U1'},
      requiredObjectivesByUnitId: const {},
    );

    expect(stale, isEmpty);
  });

  test("a unit whose required objectives changed is stale even if the "
      "learner's own answers are all still there", () {
    final stale = staleUnitIds(
      drift: const ContentDrift(
        removedActivityIds: {},
        removedCanDoIds: {'A2.U3.WRITING.OLD'},
        addedCanDoIds: {'A2.U3.WRITING.NEW'},
      ),
      attemptedLessonByActivityId: const {},
      unitIdByLessonId: const {},
      requiredObjectivesByUnitId: const {
        'A2-U3': {'A2.U3.WRITING.NEW'},
        'A2-U7': {'A2.U7.READING.UNCHANGED'},
      },
    );

    expect(stale, {'A2-U3'});
  });

  test('a unit that requires an objective which was removed is stale', () {
    final stale = staleUnitIds(
      drift: const ContentDrift(
        removedActivityIds: {},
        removedCanDoIds: {'A2.U3.WRITING.OLD'},
        addedCanDoIds: {},
      ),
      attemptedLessonByActivityId: const {},
      unitIdByLessonId: const {},
      requiredObjectivesByUnitId: const {
        'A2-U3': {'A2.U3.WRITING.OLD', 'A2.U3.READING.1'},
      },
    );

    expect(stale, {'A2-U3'});
  });

  test('canDoIdsOf covers every place an objective id can appear', () {
    // The recorder and the differ must read the same set, or every upgrade
    // reports drift that never happened. Run over the real A2 bundle so a
    // future source of objective ids that this function forgets shows up
    // here rather than as phantom staleness on a learner's device.
    final bundle = CourseBundleParser.parse(
      File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
    );
    final ids = canDoIdsOf(bundle);

    final fromLessons = <String>{};
    final fromActivities = <String>{};
    final fromMastery = <String>{};
    for (final unit in bundle.units) {
      fromMastery.addAll(unit.mastery.requiredObjectives);
      for (final lesson in unit.lessons) {
        fromLessons.addAll(lesson.canDo);
        for (final a in lesson.activities) {
          fromActivities.addAll(a.canDo);
        }
      }
    }

    expect(fromLessons, isNotEmpty);
    expect(fromActivities, isNotEmpty);
    expect(fromMastery, isNotEmpty);
    expect(ids, containsAll(fromLessons));
    expect(ids, containsAll(fromActivities));
    expect(ids, containsAll(fromMastery));
  });
}
