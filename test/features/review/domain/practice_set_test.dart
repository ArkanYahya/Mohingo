import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/review/domain/practice_set.dart';
import 'package:mohingo/features/review/domain/weak_spots.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

void main() {
  group('for a weak spot', () {
    test('up to three questions from the lesson that teaches it, each '
        'practising one of its goals, never first-exposure ones', () {
      final spot = weakSpotsFor(
        index: _index,
        levelCode: 'A1',
        canDoIds: const [
          'A1.U1.PRODUCTION.INTRODUCE_SELF',
          'A1.U1.INTERACTION.ASK_NAME',
        ],
      ).single;

      final set = practiceSetForWeakSpot(spot);

      expect(set.title, spot.lesson.title);
      expect(set.lesson, spot.lesson);
      expect(set.activities, isNotEmpty);
      expect(set.activities.length, lessThanOrEqualTo(3));
      for (final a in set.activities) {
        expect(spot.lesson.activities, contains(a));
        expect(a.mode, isNot(ActivityMode.encounter));
        expect(a.canDo.any(spot.canDoIds.contains), isTrue);
      }
    });
  });

  group('for a grammar form', () {
    test('up to three practice questions from the lessons that use it', () {
      final grammar = _index.bundle.grammar.first; // "I am"
      final set = practiceSetForGrammar(_index, grammar.id);

      expect(set.title, grammar.form);
      expect(set.activities, isNotEmpty);
      expect(set.activities.length, lessThanOrEqualTo(3));
      for (final a in set.activities) {
        expect(a.mode, ActivityMode.practice);
        final lesson = _index.lessonsById[a.lessonId]!;
        expect(lesson.grammar, contains(grammar.id));
      }
      expect(set.lesson!.grammar, contains(grammar.id));
    });

    test('a form no lesson practises gives an empty set', () {
      expect(practiceSetForGrammar(_index, 'A1.G.NOPE').activities, isEmpty);
    });
  });
}
