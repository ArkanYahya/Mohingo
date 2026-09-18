import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/home/domain/day_part.dart';
import 'package:mohingo/features/home/domain/lesson_resume.dart';

Activity _activity(String id, String lessonId) => TextChoiceActivity(
  id: id,
  lessonId: lessonId,
  mode: ActivityMode.mastery,
  skill: Skill.reading,
  canDo: const [],
  prompt: 'p',
  promptAr: 'ع',
  raw: const {},
  options: const ['a', 'b'],
  answer: 'a',
);

Lesson _lesson(String id, int activityCount) => Lesson(
  id: id,
  title: id,
  titleAr: id,
  lessonType: 'encounter-focus-practice',
  canDo: const [],
  grammar: const [],
  lexicon: const [],
  chunks: const [],
  encounterDialogue: const [],
  activities: [
    for (var i = 1; i <= activityCount; i++) _activity('$id-A$i', id),
  ],
  raw: const {},
);

Unit _unit(List<Lesson> lessons) => Unit(
  id: 'U1',
  title: 'U1',
  titleAr: 'U1',
  levelRole: 'core',
  estimatedMinutes: const [60, 90],
  countsTowardA1Mastery: true,
  lessons: lessons,
  mastery: const UnitMastery(
    requiredObjectives: [],
    requiredSkillGroups: [],
    minimumObjectiveScore: null,
    raw: {},
  ),
);

LessonProgressData _progress(String lessonId, String lastActivityId) =>
    LessonProgressData(
      id: 0,
      uuid: lessonId,
      learnerId: 1,
      lessonId: lessonId,
      unitId: 'U1',
      state: 'inProgress',
      lastActivityId: lastActivityId,
      updatedAt: DateTime.utc(2026, 9, 18),
    );

void main() {
  group('dayPartFor', () {
    test('05:00–11:59 is morning', () {
      expect(dayPartFor(5), DayPart.morning);
      expect(dayPartFor(11), DayPart.morning);
    });
    test('12:00–16:59 is afternoon', () {
      expect(dayPartFor(12), DayPart.afternoon);
      expect(dayPartFor(16), DayPart.afternoon);
    });
    test('17:00–04:59 is evening', () {
      expect(dayPartFor(17), DayPart.evening);
      expect(dayPartFor(23), DayPart.evening);
      expect(dayPartFor(0), DayPart.evening);
      expect(dayPartFor(4), DayPart.evening);
    });
  });

  group('lessonResumeFor', () {
    test('with no progress, resumes the first lesson at 0 of N', () {
      final unit = _unit([_lesson('L1', 4), _lesson('L2', 3)]);
      final resume = lessonResumeFor(unit: unit, unitLessonProgress: const []);
      expect(resume, isNotNull);
      expect(resume!.lesson.id, 'L1');
      expect(resume.lessonIndex, 0);
      expect(resume.activitiesDone, 0);
      expect(resume.fraction, 0);
    });

    test('a part-played lesson reports how many activities are done', () {
      final unit = _unit([_lesson('L1', 4)]);
      final resume = lessonResumeFor(
        unit: unit,
        unitLessonProgress: [_progress('L1', 'L1-A2')],
      );
      expect(resume!.activitiesDone, 2);
      expect(resume.fraction, 0.5);
    });

    test('a lesson played to its last activity is finished — resumes the '
        'next lesson, not the finished one', () {
      final unit = _unit([_lesson('L1', 4), _lesson('L2', 3)]);
      final resume = lessonResumeFor(
        unit: unit,
        unitLessonProgress: [_progress('L1', 'L1-A4')],
      );
      expect(resume!.lesson.id, 'L2');
      expect(resume.lessonIndex, 1);
      expect(resume.activitiesDone, 0);
    });

    test('every lesson finished returns null', () {
      final unit = _unit([_lesson('L1', 2), _lesson('L2', 2)]);
      final resume = lessonResumeFor(
        unit: unit,
        unitLessonProgress: [
          _progress('L1', 'L1-A2'),
          _progress('L2', 'L2-A2'),
        ],
      );
      expect(resume, isNull);
    });

    test("ignores progress rows that belong to other units' lessons", () {
      final unit = _unit([_lesson('L1', 4)]);
      final resume = lessonResumeFor(
        unit: unit,
        unitLessonProgress: [_progress('OTHER-L9', 'OTHER-L9-A1')],
      );
      expect(resume!.lesson.id, 'L1');
      expect(resume.activitiesDone, 0);
    });
  });
}
