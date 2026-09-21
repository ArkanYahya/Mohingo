import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/review/domain/weak_spots.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

void main() {
  test('a weak goal is named by the first lesson that teaches it — never '
      'the mission — with its unit number and the skills its activities '
      'practise', () {
    final spots = weakSpotsFor(
      index: _index,
      levelCode: 'A1',
      canDoIds: const ['A1.U1.PRODUCTION.INTRODUCE_SELF'],
    );

    expect(spots, hasLength(1));
    final spot = spots.single;
    expect(spot.lesson.id, 'A1-U1-L1');
    expect(spot.unitNumber, 2);
    expect(spot.canDoIds, ['A1.U1.PRODUCTION.INTRODUCE_SELF']);
    expect(spot.skills, contains(Skill.reading));
    expect(
      spot.skills.where(
        (s) => s == Skill.spokenProduction || s == Skill.spokenInteraction,
      ),
      hasLength(1),
      reason: 'the two speaking skills are one skill to a learner',
    );
  });

  test('goals taught by the same lesson are one weak spot', () {
    final spots = weakSpotsFor(
      index: _index,
      levelCode: 'A1',
      canDoIds: const [
        'A1.U1.PRODUCTION.INTRODUCE_SELF',
        'A1.U1.INTERACTION.ASK_NAME',
      ],
    );

    expect(spots, hasLength(1));
    expect(spots.single.canDoIds, hasLength(2));
  });

  test('listening-only goals name their lesson and skill', () {
    final spot = weakSpotsFor(
      index: _index,
      levelCode: 'A1',
      canDoIds: const ['A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO'],
    ).single;

    expect(spot.lesson.title, 'Where Are You From?');
    expect(spot.skills, [Skill.listening]);
  });

  test('an id no lesson teaches is left out rather than shown raw', () {
    expect(
      weakSpotsFor(
        index: _index,
        levelCode: 'A1',
        canDoIds: const ['A1.NOT.A.REAL.GOAL'],
      ),
      isEmpty,
    );
  });

  test('keeps the order it was given', () {
    final spots = weakSpotsFor(
      index: _index,
      levelCode: 'A1',
      canDoIds: const [
        'A1.U1.PRODUCTION.STATE_RESIDENCE',
        'A1.U1.PRODUCTION.INTRODUCE_SELF',
      ],
    );

    expect(spots.map((s) => s.lesson.id), ['A1-U1-L3', 'A1-U1-L1']);
  });
}
