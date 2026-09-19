import '../../../content/index/course_content_index.dart';
import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import 'weak_spots.dart';

/// A short quick-practice run: a few questions about one thing — a weak
/// spot's lesson or a grammar form — named by [title], with the [lesson]
/// that teaches it for "open the lesson". Quick practice is recorded as
/// `practiceReview` and never counts towards mastery (docs/DATA_MODEL.md).
class PracticeSet {
  const PracticeSet({
    required this.title,
    required this.activities,
    this.lesson,
  });

  /// What is being practised: a lesson title or a grammar form (English).
  final String title;
  final List<Activity> activities;
  final Lesson? lesson;

  /// How many questions a practice set asks at most.
  static const maxQuestions = 3;
}

/// Up to [PracticeSet.maxQuestions] questions from [spot]'s lesson that
/// practise its goals — `practice` mode first, then `mastery`; never
/// `encounter` (first exposure, nothing to practise yet).
PracticeSet practiceSetForWeakSpot(WeakSpot spot) {
  final relevant = [
    for (final a in spot.lesson.activities)
      if (a.mode != ActivityMode.encounter &&
          a.canDo.any(spot.canDoIds.contains))
        a,
  ];
  final ordered = [
    ...relevant.where((a) => a.mode == ActivityMode.practice),
    ...relevant.where((a) => a.mode != ActivityMode.practice),
  ];
  return PracticeSet(
    title: spot.lesson.title,
    lesson: spot.lesson,
    activities: ordered.take(PracticeSet.maxQuestions).toList(),
  );
}

/// Up to [PracticeSet.maxQuestions] `practice` questions from the lessons
/// that use grammar form [grammarId], in course order.
PracticeSet practiceSetForGrammar(CourseContentIndex index, String grammarId) {
  final lessons = [
    for (final unit in index.bundle.units)
      for (final lesson in unit.lessons)
        if (lesson.grammar.contains(grammarId)) lesson,
  ];
  final activities = [
    for (final lesson in lessons)
      for (final a in lesson.activities)
        if (a.mode == ActivityMode.practice) a,
  ];
  return PracticeSet(
    title: index.grammarById[grammarId]?.form ?? grammarId,
    lesson: lessons.firstOrNull,
    activities: activities.take(PracticeSet.maxQuestions).toList(),
  );
}
