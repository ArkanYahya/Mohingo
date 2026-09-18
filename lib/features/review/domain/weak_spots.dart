import '../../../content/index/course_content_index.dart';
import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';

/// One lesson's worth of Can-Do goals that need more practice, named the
/// way a learner knows it — the lesson that teaches them — rather than by
/// the goals' internal ids (the bundle carries no learner-facing Can-Do
/// text).
class WeakSpot {
  const WeakSpot({
    required this.lesson,
    required this.unitNumber,
    required this.canDoIds,
    required this.skills,
    required this.practiceActivity,
  });

  /// The first non-mission lesson that teaches the goals.
  final Lesson lesson;

  /// The lesson's unit's 1-based position in the course.
  final int unitNumber;

  final List<String> canDoIds;

  /// The skills the goals' activities practise, in first-seen order, with
  /// spoken interaction and spoken production counted once (a learner
  /// sees both as "Speaking").
  final List<Skill> skills;

  /// An activity for these goals from [lesson], for quick practice.
  final Activity? practiceActivity;
}

bool _isSpeaking(Skill s) =>
    s == Skill.spokenInteraction || s == Skill.spokenProduction;

/// Groups [canDoIds] into [WeakSpot]s by the lesson that teaches each, in
/// the order the ids first appear. An id no lesson teaches is left out.
List<WeakSpot> weakSpotsFor({
  required CourseContentIndex index,
  required List<String> canDoIds,
}) {
  final units = index.bundle.units;
  final byLessonId = <String, List<String>>{};
  final lessonById = <String, Lesson>{};
  final unitNumberByLessonId = <String, int>{};

  for (final canDoId in canDoIds) {
    Lesson? teacher;
    var unitNumber = 0;
    for (final (u, unit) in units.indexed) {
      for (final lesson in unit.lessons) {
        if (lesson.lessonType == 'mission') continue;
        if (lesson.canDo.contains(canDoId)) {
          teacher = lesson;
          unitNumber = u + 1;
          break;
        }
      }
      if (teacher != null) break;
    }
    if (teacher == null) continue;
    lessonById[teacher.id] = teacher;
    unitNumberByLessonId[teacher.id] = unitNumber;
    byLessonId.putIfAbsent(teacher.id, () => []).add(canDoId);
  }

  return [
    for (final MapEntry(key: lessonId, value: ids) in byLessonId.entries)
      _spot(index, lessonById[lessonId]!, unitNumberByLessonId[lessonId]!, ids),
  ];
}

WeakSpot _spot(
  CourseContentIndex index,
  Lesson lesson,
  int unitNumber,
  List<String> canDoIds,
) {
  final activities = [
    for (final id in canDoIds) ...?index.activitiesByCanDoId[id],
  ];
  final skills = <Skill>[];
  for (final a in activities) {
    final seen = skills.any(
      (s) => s == a.skill || (_isSpeaking(s) && _isSpeaking(a.skill)),
    );
    if (!seen) skills.add(a.skill);
  }
  final practice = activities.where(lesson.activities.contains).firstOrNull;
  return WeakSpot(
    lesson: lesson,
    unitNumber: unitNumber,
    canDoIds: canDoIds,
    skills: skills,
    practiceActivity: practice ?? activities.firstOrNull,
  );
}
