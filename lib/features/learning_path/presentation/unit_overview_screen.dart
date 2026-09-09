import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../domain/lesson_status_selector.dart';
import '../providers/unit_progress_providers.dart';

/// Shows one unit's lessons, each with a [StatusIndicator] derived from
/// whether the learner's recorded position in that lesson has reached its
/// final activity. Every lesson is always tappable — free access, no hard
/// lock — per docs/PRODUCT.md flow 5. Tapping a lesson that's genuinely
/// finished opens a read-only `LessonReviewScreen` of the learner's latest
/// answers first, rather than replaying it directly; its own "Practice
/// again" button is what actually replays the lesson from the start and
/// appends fresh evidence rather than overwriting history — see
/// docs/DATA_MODEL.md and docs/superpowers/specs/
/// 2026-09-09-lesson-answer-review-design.md. A not-started or mid-lesson
/// tap still goes straight into the live player, resuming where the
/// learner left off, exactly as before.
class UnitOverviewScreen extends ConsumerWidget {
  const UnitOverviewScreen({required this.unitId, super.key});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final unit = index.unitsById[unitId];
        if (unit == null) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }
        return learnerAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
          data: (learner) =>
              _UnitOverviewBody(unit: unit, learnerId: learner.id),
        );
      },
    );
  }
}

class _UnitOverviewBody extends ConsumerWidget {
  const _UnitOverviewBody({required this.unit, required this.learnerId});

  final Unit unit;
  final int learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(
      lessonProgressForUnitProvider((learnerId: learnerId, unitId: unit.id)),
    );
    final attemptsAsync = ref.watch(
      lessonAttemptsForUnitProvider((learnerId: learnerId, unitId: unit.id)),
    );

    return progressAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (rows) {
        final progressByLessonId = {for (final row in rows) row.lessonId: row};
        final lessonAttempts = attemptsAsync.value ?? const [];

        return Scaffold(
          appBar: AppBar(title: Text(unit.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lesson in unit.lessons)
                _lessonRow(
                  context,
                  lesson,
                  progressByLessonId[lesson.id],
                  lessonAttempts,
                ),
            ],
          ),
        );
      },
    );
  }

  /// One lesson's tappable row. Reused between the "genuinely finished"
  /// (read-only review) and "not started"/"mid-lesson" (resume/start the
  /// real player) cases — [isFinished] is the same "reached the lesson's
  /// final activity" signal `lesson_player_screen.dart`'s
  /// `_resolveStartIndex` uses, derived once here via [lessonStatus] so the
  /// status dot and the tap target never disagree. See
  /// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
  Widget _lessonRow(
    BuildContext context,
    Lesson lesson,
    LessonProgressData? row,
    List<ActivityAttempt> lessonAttempts,
  ) {
    final state = lessonStatus(
      lesson: lesson,
      progress: row,
      lessonAttempts: lessonAttempts,
    );
    final isFinished =
        state == ProgressState.mastered || state == ProgressState.needsReview;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // No invalidate-on-return here: the lesson player invalidates
          // [lessonProgressForUnitProvider] itself the moment a lesson is
          // finished, which covers both its "Back to unit" (pop) and "Next
          // lesson" (pushReplacement) exits. See that provider's doc
          // comment.
          onTap: () => context.push(
            isFinished
                ? '/lesson-review/${unit.id}/${lesson.id}'
                : '/lesson-player/${unit.id}/${lesson.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _lessonStatusIndicator(context, state),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        lesson.titleAr,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The lesson row's status dot. A finished, all-correct lesson
  /// deliberately announces "Completed" rather than the shared "Mastered"
  /// label: reaching a lesson's last activity is not course mastery as
  /// docs/GLOSSARY.md defines it (that is `MasteryAggregationService`'s
  /// call, made per unit against Can-Do evidence). A finished lesson with
  /// at least one wrong answer shows `needsReview` instead, using its own
  /// default "Needs review" label — see [lessonStatus].
  Widget _lessonStatusIndicator(BuildContext context, ProgressState state) {
    return StatusIndicator(
      state: state,
      size: 20,
      semanticLabelOverride: state == ProgressState.mastered
          ? AppLocalizations.of(context)!.lessonStateCompleted
          : null,
    );
  }
}
