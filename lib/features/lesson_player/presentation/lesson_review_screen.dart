import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/local/database.dart';
import '../../activity_engine/presentation/activity_chrome.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Every recorded attempt for one lesson's activities, for one learner —
/// feeds [LessonReviewScreen]'s "latest attempt per activity" reduction.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final lessonReviewAttemptsProvider =
    FutureProvider.family<
      List<ActivityAttempt>,
      ({int learnerId, String lessonId})
    >((ref, params) {
      final repository = ref.watch(activityAttemptRepositoryProvider);
      return repository.attemptsForLessons(
        learnerId: params.learnerId,
        lessonIds: [params.lessonId],
      );
    });

/// Reduces [attempts] to the single latest attempt per activity id, for
/// activities that actually belong to [lesson] — the same reduction
/// `lesson_player_screen.dart`'s `_rehydratePreviousAnswers` performs (kept
/// as a separate function here since the two screens use the result for
/// different purposes). Restricted to `sessionType == 'lesson'`:
/// placement/mission/assessment attempts never leak into ordinary lesson
/// review. See docs/DATA_MODEL.md.
Map<String, ActivityAttempt> latestAttemptPerActivity(
  List<ActivityAttempt> attempts,
  Lesson lesson,
) {
  final activityIds = lesson.activities.map((a) => a.id).toSet();
  final latest = <String, ActivityAttempt>{};
  for (final attempt in attempts) {
    if (attempt.sessionType != 'lesson') continue;
    if (!activityIds.contains(attempt.activityId)) continue;
    final existing = latest[attempt.activityId];
    if (existing == null ||
        !attempt.attemptedAt.isBefore(existing.attemptedAt)) {
      latest[attempt.activityId] = attempt;
    }
  }
  return latest;
}

/// Read-only walkthrough of a learner's latest answer to every activity in
/// an already-finished lesson — the Learn tab's answer-review feature. Shown
/// instead of [LessonPlayerScreen] when `UnitOverviewScreen` detects the
/// lesson has already reached its final activity. "Practice again" is the
/// only door back into the real (replaying, evidence-recording) player. See
/// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
class LessonReviewScreen extends ConsumerWidget {
  const LessonReviewScreen({
    required this.unitId,
    required this.lessonId,
    super.key,
  });

  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) {
        final lesson = index.lessonsById[lessonId];
        if (lesson == null) {
          return const _ErrorScaffold(message: 'Lesson not found');
        }
        return learnerAsync.when(
          loading: () => const _LoadingScaffold(),
          error: (error, _) => _ErrorScaffold(message: '$error'),
          data: (learner) => _LessonReviewBody(
            unitId: unitId,
            lesson: lesson,
            learnerId: learner.id,
            mediaByKey: index.bundle.mediaSpecifications,
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}

class _LessonReviewBody extends ConsumerWidget {
  const _LessonReviewBody({
    required this.unitId,
    required this.lesson,
    required this.learnerId,
    required this.mediaByKey,
  });

  final String unitId;
  final Lesson lesson;
  final int learnerId;
  final Map<String, MediaSpecification> mediaByKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(
      lessonReviewAttemptsProvider((learnerId: learnerId, lessonId: lesson.id)),
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: attemptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (attempts) {
          final latest = latestAttemptPerActivity(attempts, lesson);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final activity in lesson.activities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: latest[activity.id] == null
                        ? _NotAnsweredCard(activity: activity)
                        : buildActivityView(
                            key: ValueKey(activity.id),
                            activity,
                            learnerId: learnerId,
                            onSubmitted: (_) {},
                            mediaByKey: mediaByKey,
                            reviewAttempt: latest[activity.id],
                          ),
                  ),
                FilledButton(
                  onPressed: () =>
                      context.push('/lesson-player/$unitId/${lesson.id}'),
                  child: Text(l10n.lessonReviewPracticeAgain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotAnsweredCard extends StatelessWidget {
  const _NotAnsweredCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ActivityChrome(
      prompt: activity.prompt,
      promptAr: activity.promptAr,
      body: Text(
        l10n.lessonReviewNotAnswered,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
