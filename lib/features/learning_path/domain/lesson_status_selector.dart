import '../../../content/models/curriculum_structure.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';

/// Determines one lesson's status for the unit overview.
///
/// A lesson with no recorded position is [ProgressState.notStarted]. One
/// whose last recorded activity isn't yet the lesson's final activity is
/// [ProgressState.inProgress]. A lesson that reached its final activity is
/// [ProgressState.mastered] only if every activity's *most recent* attempt
/// was correct (a mistake later corrected on replay doesn't count against
/// it — [ActivityAttemptRepository.recordAttempt] is insert-only, so an
/// old wrong attempt can outlive a later correct one); if any activity's
/// most recent attempt was wrong, it's [ProgressState.needsReview] instead.
/// A not-auto-graded attempt (writing/speaking pending a rubric) is never
/// treated as wrong.
ProgressState lessonStatus({
  required Lesson lesson,
  required LessonProgressData? progress,
  required List<ActivityAttempt> lessonAttempts,
}) {
  if (progress == null || lesson.activities.isEmpty) {
    return ProgressState.notStarted;
  }

  final lastActivityId = progress.lastActivityId;
  final isFinished =
      lastActivityId != null && lastActivityId == lesson.activities.last.id;
  if (!isFinished) return ProgressState.inProgress;

  final latestByActivity = <String, ActivityAttempt>{};
  for (final attempt in lessonAttempts) {
    if (attempt.lessonId != lesson.id) continue;
    final existing = latestByActivity[attempt.activityId];
    if (existing == null || attempt.attemptedAt.isAfter(existing.attemptedAt)) {
      latestByActivity[attempt.activityId] = attempt;
    }
  }

  final hasWrongAnswer = latestByActivity.values.any(
    (a) => a.isCorrect == false,
  );
  return hasWrongAnswer ? ProgressState.needsReview : ProgressState.mastered;
}
