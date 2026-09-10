import '../../../content/models/curriculum_structure.dart';
import '../../../core/widgets/status_indicator.dart';

/// Picks which lesson within a unit is the learner's "current" position —
/// the highlighted node on the unit overview's lesson path. Unlike
/// [currentUnitId] (which prefers the most recently active unit), lessons
/// within one unit are meant to be done in curriculum order, so this is
/// simply the first lesson whose status isn't finished
/// ([ProgressState.mastered]/[ProgressState.needsReview]). `null` when
/// every lesson is finished, or [lessons] is empty.
String? currentLessonId({
  required List<Lesson> lessons,
  required Map<String, ProgressState> statusByLessonId,
}) {
  for (final lesson in lessons) {
    final state = statusByLessonId[lesson.id] ?? ProgressState.notStarted;
    if (state != ProgressState.mastered && state != ProgressState.needsReview) {
      return lesson.id;
    }
  }
  return null;
}
