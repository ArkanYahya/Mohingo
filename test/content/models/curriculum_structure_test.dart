import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';

Map<String, dynamic> _lesson({Map<String, dynamic>? readingText}) => {
  'id': 'A1-U2-L6',
  'title': 'A People Profile',
  'titleAr': 'ملف عن الناس',
  'lessonType': 'encounter-focus-practice',
  'canDo': <String>[],
  'activities': <Map<String, dynamic>>[],
  'readingText': ?readingText,
};

Map<String, dynamic> _unit(Map<String, dynamic> countsToward) => {
  'id': 'A2-U1',
  'title': 'Life Now',
  'titleAr': 'حياتي الآن',
  'levelRole': 'core',
  'estimatedMinutes': [95, 130],
  ...countsToward,
  'lessons': <Map<String, dynamic>>[],
  'mastery': {'requiredObjectives': <String>[]},
};

void main() {
  test("a lesson's model text is parsed with its Arabic", () {
    final lesson = Lesson.fromJson(
      _lesson(
        readingText: {
          'title': "Maya's Family",
          'text': 'My name is Maya.',
          'textAr': 'اسمي مايا.',
        },
      ),
    );
    expect(lesson.readingText!.title, "Maya's Family");
    expect(lesson.readingText!.text, 'My name is Maya.');
    expect(lesson.readingText!.textAr, 'اسمي مايا.');
  });

  test('a lesson without a model text has none', () {
    expect(Lesson.fromJson(_lesson()).readingText, isNull);
  });

  test('whether a unit counts towards its level is read from any level '
      'name the bundle uses', () {
    expect(
      Unit.fromJson(_unit({'countsTowardA1Mastery': false}))
          .countsTowardLevelMastery,
      isFalse,
    );
    expect(
      Unit.fromJson(_unit({'countsTowardA2Mastery': true}))
          .countsTowardLevelMastery,
      isTrue,
    );
    expect(
      Unit.fromJson(_unit({'countsTowardLevelMastery': true}))
          .countsTowardLevelMastery,
      isTrue,
    );
  });
}
