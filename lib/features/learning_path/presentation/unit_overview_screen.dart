import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../domain/current_lesson_selector.dart';
import '../domain/lesson_status_selector.dart';
import '../providers/unit_progress_providers.dart';

/// Shows one unit's lessons as a vertical path of circular icon nodes
/// (mirroring Learn's unit spine, scaled to lesson granularity), each with
/// a [StatusIndicator] derived from whether the learner's recorded position
/// in that lesson has reached its final activity, plus a header progress
/// bar ("N of M lessons complete"). Every lesson is always tappable — free
/// access, no hard lock — per docs/PRODUCT.md flow 5. Tapping a lesson
/// that's genuinely finished opens a read-only `LessonReviewScreen` of the
/// learner's latest answers first, rather than replaying it directly; its
/// own "Practice again" button is what actually replays the lesson from the
/// start and appends fresh evidence rather than overwriting history — see
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

        final statusByLessonId = {
          for (final lesson in unit.lessons)
            lesson.id: lessonStatus(
              lesson: lesson,
              progress: progressByLessonId[lesson.id],
              lessonAttempts: lessonAttempts,
            ),
        };
        final completedCount = statusByLessonId.values
            .where(
              (s) =>
                  s == ProgressState.mastered || s == ProgressState.needsReview,
            )
            .length;
        final currentId = currentLessonId(
          lessons: unit.lessons,
          statusByLessonId: statusByLessonId,
        );

        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        final fraction = unit.lessons.isEmpty
            ? 0.0
            : completedCount / unit.lessons.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(unit.title, textDirection: TextDirection.ltr),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.unitOverviewLessonsComplete(
                        completedCount,
                        unit.lessons.length,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < unit.lessons.length; i++) ...[
                _LessonNode(
                  unit: unit,
                  lesson: unit.lessons[i],
                  state: statusByLessonId[unit.lessons[i].id]!,
                  isCurrent: unit.lessons[i].id == currentId,
                ),
                if (i != unit.lessons.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One lesson's tappable node. [isCurrent] highlights the single lesson
/// the learner should do next (see [currentLessonId]) with the brand
/// accent, regardless of whether its raw [state] is `notStarted` or
/// `inProgress` — the highlight means "do this one," not the state itself.
/// A `lessonType == 'mission'` lesson renders as a distinct solid card
/// instead (mirrors Learn's unit spine's own mission-milestone treatment).
class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.unit,
    required this.lesson,
    required this.state,
    required this.isCurrent,
  });

  final Unit unit;
  final Lesson lesson;
  final ProgressState state;
  final bool isCurrent;

  bool get _isFinished =>
      state == ProgressState.mastered || state == ProgressState.needsReview;

  void _onTap(BuildContext context) {
    context.push(
      _isFinished
          ? '/lesson-review/${unit.id}/${lesson.id}'
          : '/lesson-player/${unit.id}/${lesson.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    final isMission = lesson.lessonType == 'mission';

    if (isMission) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTap(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onPrimary.withValues(alpha: 0.16),
                    border: Border.all(color: colorScheme.onPrimary, width: 2),
                  ),
                  child: Icon(Icons.flag, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        lesson.titleAr,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onPrimary),
              ],
            ),
          ),
        ),
      );
    }

    final (
      Color? rowFill,
      Color? rowBorder,
      Color? nodeColor,
    ) = switch (state) {
      ProgressState.mastered => (
        feedbackTheme.successContainer,
        null,
        feedbackTheme.success,
      ),
      _ when isCurrent => (
        colorScheme.primaryContainer,
        colorScheme.primary,
        colorScheme.primary,
      ),
      _ => (null, null, null),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: rowFill,
            borderRadius: BorderRadius.circular(16),
            border: rowBorder != null
                ? Border.all(color: rowBorder, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == ProgressState.mastered
                      ? feedbackTheme.success
                      : colorScheme.surface,
                  border: state == ProgressState.mastered
                      ? null
                      : Border.all(
                          color: nodeColor ?? colorScheme.outlineVariant,
                          width: isCurrent ? 2.5 : 2,
                        ),
                ),
                child: Center(
                  child: StatusIndicator(
                    state: state,
                    size: 24,
                    colorOverride: state == ProgressState.mastered
                        ? feedbackTheme.onSuccess
                        : nodeColor,
                    semanticLabelOverride: state == ProgressState.mastered
                        ? l10n.lessonStateCompleted
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
              Icon(
                Icons.chevron_right,
                color: isCurrent ? colorScheme.primary : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
