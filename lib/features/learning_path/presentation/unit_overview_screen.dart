import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/lesson_type_label.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../domain/current_lesson_selector.dart';
import '../domain/lesson_status_selector.dart';
import '../providers/unit_progress_providers.dart';
import 'widgets/path_row.dart';

/// Shows one unit's lessons as a path — the same numbered nodes on a rail
/// as the Learn tab's course page ([PathRow]) — each with its type, size
/// and a conversation mark, or, once finished, a line saying its answers
/// can be reviewed. The lesson to do now (see [currentLessonId]) is the one
/// highlighted card with a Start/Continue button; the unit mission is a
/// flag-marked card. A header gives the unit's size and lessons complete.
///
/// Every lesson is always tappable — free access, no hard lock — per
/// docs/PRODUCT.md flow 5. Tapping a lesson that's genuinely finished opens
/// a read-only `LessonReviewScreen` of the learner's latest answers first,
/// rather than replaying it directly; its own "Practice again" button is
/// what actually replays the lesson from the start and appends fresh
/// evidence rather than overwriting history — see docs/DATA_MODEL.md and
/// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md. A
/// not-started or mid-lesson tap goes straight into the live player,
/// resuming where the learner left off.
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
          data: (learner) => _UnitOverviewBody(
            unit: unit,
            unitNumber:
                index.bundle.units.indexWhere((u) => u.id == unit.id) + 1,
            learnerId: learner.id,
          ),
        );
      },
    );
  }
}

class _UnitOverviewBody extends ConsumerWidget {
  const _UnitOverviewBody({
    required this.unit,
    required this.unitNumber,
    required this.learnerId,
  });

  final Unit unit;
  final int unitNumber;
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

        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            children: [
              _UnitHeader(
                unit: unit,
                unitNumber: unitNumber,
                completedCount: completedCount,
              ),
              const SizedBox(height: AppSpace.md),
              for (final (i, lesson) in unit.lessons.indexed)
                _LessonRow(
                  unit: unit,
                  lesson: lesson,
                  number: i + 1,
                  state: statusByLessonId[lesson.id]!,
                  isCurrent: lesson.id == currentId,
                  activitiesDone: _activitiesDone(
                    lesson,
                    progressByLessonId[lesson.id],
                  ),
                  isFirst: i == 0,
                  isLast: i == unit.lessons.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Activities answered in [lesson], from its resume pointer.
int _activitiesDone(Lesson lesson, LessonProgressData? progress) {
  final lastId = progress?.lastActivityId;
  if (lastId == null) return 0;
  return lesson.activities.indexWhere((a) => a.id == lastId) + 1;
}

/// "UNIT 2", the unit's title in English and Arabic, its size and time, and
/// lessons complete over an ink bar.
class _UnitHeader extends StatelessWidget {
  const _UnitHeader({
    required this.unit,
    required this.unitNumber,
    required this.completedCount,
  });

  final Unit unit;
  final int unitNumber;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final total = unit.lessons.length;
    final minutes = unit.estimatedMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.learnUnitOverline(unitNumber).toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xxs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            unit.title,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            unit.titleAr,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          minutes.length == 2
              ? '${l10n.learnLessonCount(total)} · '
                    '${l10n.learnUnitMinutes(minutes[0], minutes[1])}'
              : l10n.learnLessonCount(total),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.unitOverviewLessonsComplete(completedCount, total),
          style: theme.textTheme.titleSmall?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpace.xs - 2),
        _InkBar(value: total == 0 ? 0 : completedCount / total),
      ],
    );
  }
}

/// The 6dp progress bar shared with the course page's current-unit card.
class _InkBar extends StatelessWidget {
  const _InkBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        color: tokens.primaryInk,
        backgroundColor: Color.lerp(tokens.border, tokens.textSecondary, 0.15),
      ),
    );
  }
}

/// One lesson on the unit's path. A finished lesson opens its read-only
/// answer review; anything else opens the live player (see the class
/// comment on [UnitOverviewScreen]).
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.unit,
    required this.lesson,
    required this.number,
    required this.state,
    required this.isCurrent,
    required this.activitiesDone,
    required this.isFirst,
    required this.isLast,
  });

  final Unit unit;
  final Lesson lesson;
  final int number;
  final ProgressState state;
  final bool isCurrent;
  final int activitiesDone;
  final bool isFirst;
  final bool isLast;

  bool get _isFinished =>
      state == ProgressState.mastered || state == ProgressState.needsReview;

  bool get _isMission => lesson.lessonType == 'mission';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stateLabel = switch (state) {
      ProgressState.mastered => l10n.lessonStateCompleted,
      ProgressState.needsReview => l10n.unitStateNeedsReview,
      ProgressState.inProgress => l10n.unitStateInProgress,
      ProgressState.notStarted => l10n.unitStateNotStarted,
    };
    final kind = switch (state) {
      ProgressState.mastered => PathNodeKind.done,
      ProgressState.needsReview => PathNodeKind.review,
      _ when isCurrent => PathNodeKind.current,
      _ when _isMission => PathNodeKind.flag,
      _ => PathNodeKind.upcoming,
    };
    void open() => context.push(
      _isFinished
          ? '/lesson-review/${unit.id}/${lesson.id}'
          : '/lesson-player/${unit.id}/${lesson.id}',
    );
    final isCard = isCurrent || (_isMission && !_isFinished);

    return PathRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: isCard ? null : open,
      node: PathNode(
        kind: kind,
        number: number,
        semanticsLabel: l10n.learnLessonNodeSemantics(number, stateLabel),
      ),
      child: isCurrent
          ? _CurrentLessonCard(
              lesson: lesson,
              number: number,
              isMission: _isMission,
              activitiesDone: activitiesDone,
              onOpen: open,
            )
          : isCard
          ? _MissionCard(lesson: lesson, onOpen: open)
          : _LessonSummary(lesson: lesson, state: state),
    );
  }
}

/// A lesson's type and size — "Guided lesson · 4 activities" — with a
/// small conversation mark when it opens with one. A mission shows its
/// purpose ([suffix]) instead of its type.
class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.lesson, this.suffix});

  final Lesson lesson;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final type = suffix == null
        ? lessonTypeLabel(l10n, lesson.lessonType)
        : null;
    final text = [
      ?type,
      l10n.homeActivityCount(lesson.activities.length),
      ?suffix,
    ].join(' · ');

    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
        if (lesson.encounterDialogue.isNotEmpty) ...[
          const SizedBox(width: AppSpace.xs - 2),
          Semantics(
            container: true,
            label: l10n.learnLessonHasConversation,
            child: ExcludeSemantics(
              child: Icon(
                Icons.forum_outlined,
                size: 16,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A lesson's English title with its Arabic beneath.
class _LessonTitle extends StatelessWidget {
  const _LessonTitle({required this.lesson, this.large = false});

  final Lesson lesson;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final titleStyle = large
        ? theme.textTheme.titleLarge
        : theme.textTheme.titleMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            lesson.title,
            textDirection: TextDirection.ltr,
            style: titleStyle?.copyWith(color: tokens.textPrimary),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            lesson.titleAr,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A plain row's content: title, Arabic, then either the lesson's type and
/// size or — once finished — a line saying its answers can be reviewed.
class _LessonSummary extends StatelessWidget {
  const _LessonSummary({required this.lesson, required this.state});

  final Lesson lesson;
  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    final (IconData, Color, String)? status = switch (state) {
      ProgressState.mastered => (
        Icons.check_rounded,
        theme.extension<FeedbackTheme>()!.success,
        l10n.learnLessonCompletedReview,
      ),
      ProgressState.needsReview => (
        Icons.refresh_rounded,
        theme.extension<GamificationTheme>()!.streakAccent,
        l10n.learnLessonNeedsReviewReview,
      ),
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LessonTitle(lesson: lesson),
        const SizedBox(height: AppSpace.xxs),
        if (status case (final icon, final color, final label))
          Row(
            children: [
              ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
              const SizedBox(width: AppSpace.xs - 2),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          )
        else
          _LessonMeta(lesson: lesson),
      ],
    );
  }
}

/// The unit's mission, not yet played and not the lesson to do now: a
/// quiet bordered card with a "UNIT MISSION" overline beside the flag.
class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.lesson, required this.onOpen});

  final Lesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.learnMissionOverline.toUpperCase(),
                style: overlineStyle(context, color: tokens.textSecondary),
              ),
              const SizedBox(height: AppSpace.xxs),
              _LessonTitle(lesson: lesson),
              const SizedBox(height: AppSpace.xxs),
              _LessonMeta(lesson: lesson, suffix: l10n.learnMissionBody),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one emphasised card on the unit page: the lesson to do now, its
/// type and size, how far into it the learner is, and a button into it.
class _CurrentLessonCard extends StatelessWidget {
  const _CurrentLessonCard({
    required this.lesson,
    required this.number,
    required this.isMission,
    required this.activitiesDone,
    required this.onOpen,
  });

  final Lesson lesson;
  final int number;
  final bool isMission;
  final int activitiesDone;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final started = activitiesDone > 0;
    final total = lesson.activities.length;
    final overline = isMission
        ? l10n.learnMissionOverline
        : started
        ? l10n.learnLessonInProgressOverline(number)
        : l10n.learnLessonStartHereOverline(number);

    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.primaryInk, width: 2),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                overline.toUpperCase(),
                style: overlineStyle(context, color: tokens.primaryInk),
              ),
              const SizedBox(height: AppSpace.xxs),
              _LessonTitle(lesson: lesson, large: true),
              const SizedBox(height: AppSpace.xs),
              _LessonMeta(
                lesson: lesson,
                suffix: isMission ? l10n.learnMissionBody : null,
              ),
              if (started) ...[
                const SizedBox(height: AppSpace.sm),
                _InkBar(value: total == 0 ? 0 : activitiesDone / total),
              ],
              const SizedBox(height: AppSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton(
                  onPressed: onOpen,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          started
                              ? l10n.homeContinueLessonCta
                              : l10n.homeStartLessonCta,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
