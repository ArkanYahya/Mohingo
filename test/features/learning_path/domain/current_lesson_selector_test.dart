import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/features/learning_path/domain/current_lesson_selector.dart';

Lesson _lesson(String id) => Lesson(
  id: id,
  title: id,
  titleAr: id,
  lessonType: 'focus-practice',
  canDo: const [],
  grammar: const [],
  lexicon: const [],
  chunks: const [],
  encounterDialogue: const [],
  activities: const [],
  raw: const {},
);

void main() {
  test('with no progress anywhere, the first lesson in curriculum order is '
      'current', () {
    final lessons = [_lesson('L1'), _lesson('L2'), _lesson('L3')];
    expect(currentLessonId(lessons: lessons, statusByLessonId: const {}), 'L1');
  });

  test('the first non-finished lesson after some mastered ones is current, '
      'not the first lesson overall', () {
    final lessons = [_lesson('L1'), _lesson('L2'), _lesson('L3')];
    final status = {
      'L1': ProgressState.mastered,
      'L2': ProgressState.notStarted,
      'L3': ProgressState.notStarted,
    };
    expect(currentLessonId(lessons: lessons, statusByLessonId: status), 'L2');
  });

  test('needsReview counts as finished — the next lesson after it is '
      'current, not the needsReview lesson itself', () {
    final lessons = [_lesson('L1'), _lesson('L2'), _lesson('L3')];
    final status = {
      'L1': ProgressState.needsReview,
      'L2': ProgressState.notStarted,
      'L3': ProgressState.notStarted,
    };
    expect(currentLessonId(lessons: lessons, statusByLessonId: status), 'L2');
  });

  test('a lesson mid-way through (inProgress) is current', () {
    final lessons = [_lesson('L1'), _lesson('L2')];
    final status = {
      'L1': ProgressState.mastered,
      'L2': ProgressState.inProgress,
    };
    expect(currentLessonId(lessons: lessons, statusByLessonId: status), 'L2');
  });

  test('every lesson finished (mastered/needsReview) means no lesson is '
      'current — returns null', () {
    final lessons = [_lesson('L1'), _lesson('L2')];
    final status = {
      'L1': ProgressState.mastered,
      'L2': ProgressState.needsReview,
    };
    expect(currentLessonId(lessons: lessons, statusByLessonId: status), isNull);
  });

  test('an empty lesson list returns null', () {
    expect(
      currentLessonId(lessons: const [], statusByLessonId: const {}),
      isNull,
    );
  });
}
