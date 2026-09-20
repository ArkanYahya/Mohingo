import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'a2_finished_units.dart';

void main() {
  test('the finished list is not empty', () {
    // Every other gate in this directory iterates that list. An empty list
    // would make all of them pass while asserting nothing.
    expect(a2FinishedUnitIds, isNotEmpty);
  });

  test('each finished unit has 7 lessons and 36 activities, split 6/12/18', () {
    for (final unit in finishedA2Units()) {
      expect(unit.lessons.length, 7, reason: '${unit.id} lessons');
      final acts = activitiesOf(unit).toList();
      expect(acts.length, 36, reason: '${unit.id} activities');
      int count(ActivityMode m) => acts.where((a) => a.mode == m).length;
      expect(count(ActivityMode.encounter), 6, reason: '${unit.id} encounter');
      expect(count(ActivityMode.practice), 12, reason: '${unit.id} practice');
      expect(count(ActivityMode.mastery), 18, reason: '${unit.id} mastery');
    }
  });

  test('every grammar, lexicon and chunk reference resolves in A2 or A1', () {
    final a2 = loadA2Bundle();
    final a1 = loadA1Bundle();
    final known = {
      ...a2.grammar.map((g) => g.id),
      ...a2.lexicon.map((l) => l.id),
      ...a2.chunks.map((c) => c.id),
      ...a1.grammar.map((g) => g.id),
      ...a1.lexicon.map((l) => l.id),
      ...a1.chunks.map((c) => c.id),
    };
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final id in [
          ...lesson.grammar,
          ...lesson.lexicon,
          ...lesson.chunks,
        ]) {
          expect(known, contains(id), reason: '${lesson.id} references $id');
        }
      }
    }
  });

  test('no id is shared between A1 and A2', () {
    Set<String> ids(CourseBundle b) => {
      for (final u in b.units) ...[
        u.id,
        for (final l in u.lessons) ...[
          l.id,
          for (final a in l.activities) a.id,
        ],
      ],
    };
    expect(ids(loadA1Bundle()).intersection(ids(loadA2Bundle())), isEmpty);
  });
}
