import '../../../content/models/curriculum_structure.dart';
import '../../../data/local/database.dart';

/// The lesson Home's hero card offers to resume, and how far into it the
/// learner is.
class LessonResume {
  const LessonResume({
    required this.lesson,
    required this.lessonIndex,
    required this.activitiesDone,
  });

  final Lesson lesson;

  /// Zero-based position of [lesson] within its unit.
  final int lessonIndex;

  /// Activities already answered, read from the lesson's resume pointer.
  final int activitiesDone;

  int get activityCount => lesson.activities.length;

  double get fraction =>
      activityCount == 0 ? 0 : activitiesDone / activityCount;
}

/// The first lesson in [unit], in curriculum order, that hasn't been played
/// to its last activity — the same "finished" test `lesson_status_selector`
/// and the lesson player's resume logic use. `null` when every lesson in
/// the unit has been played through.
LessonResume? lessonResumeFor({
  required Unit unit,
  required List<LessonProgressData> unitLessonProgress,
}) {
  final progressByLessonId = {
    for (final row in unitLessonProgress) row.lessonId: row,
  };
  for (var i = 0; i < unit.lessons.length; i++) {
    final lesson = unit.lessons[i];
    final activities = lesson.activities;
    final lastActivityId = progressByLessonId[lesson.id]?.lastActivityId;
    final position = lastActivityId == null
        ? -1
        : activities.indexWhere((a) => a.id == lastActivityId);
    final finished = activities.isNotEmpty && position == activities.length - 1;
    if (finished) continue;
    return LessonResume(
      lesson: lesson,
      lessonIndex: i,
      activitiesDone: position + 1,
    );
  }
  return null;
}
