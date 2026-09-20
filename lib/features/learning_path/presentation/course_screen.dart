import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/index/course_content_index.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/local/database.dart';
import '../../progress/domain/level_access.dart';
import '../../progress/providers/level_providers.dart';
import '../domain/current_unit_selector.dart';
import '../domain/lesson_resume.dart';
import '../providers/unit_progress_providers.dart';
import 'widgets/level_strip.dart';
import 'widgets/path_row.dart';

/// The Learn tab: the course the learner is in, not always A1.
///
/// Under the course title, a level strip shows every CEFR level with
/// content — the one the learner is in filled, an open one tappable, a
/// locked one behind a small lock, and the rest inert until they have
/// content (see [LevelStrip]). Below it, a header (course title in English
/// and Arabic, units mastered with one segment per unit), then the units as
/// one path — each a numbered node on a rail with its title, Arabic, and
/// size or status. The unit the learner is working on (see [currentUnitId])
/// is the only highlighted card: its lessons done, the next lesson, and a
/// button straight into it. The path ends at the level's final mission &
/// assessment (the Tests tab).
///
/// Every unit stays tappable — free access, no hard lock — per
/// docs/PRODUCT.md flow 5.
class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

/// No local state of its own yet: Task 9 adds the field that tracks a
/// level the learner is browsing without switching into it. Starting this
/// class as a [ConsumerStatefulWidget] now avoids converting it — and
/// re-threading `ref` through it — a second time.
class _CourseScreenState extends ConsumerState<CourseScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLevelIdAsync = ref.watch(currentLevelIdProvider);
    final catalog = ref.watch(levelCatalogProvider);
    final unitProgress = ref.watch(allUnitProgressProvider).value ?? const [];
    final lessonProgress =
        ref.watch(allLessonProgressProvider).value ?? const [];

    // A level whose access hasn't resolved yet is simply left out of the
    // map — the strip renders it as coming later until it does, rather
    // than letting one slow/failing level take the whole page down.
    final access = <String, LevelAccess>{};
    for (final entry in catalog) {
      final resolved = ref.watch(levelAccessProvider(entry.levelId)).value;
      if (resolved != null) access[entry.levelId] = resolved;
    }

    // For now the shown level is always the current one; Task 9 adds a
    // separate browsing level that doesn't move the learner's enrolment.
    final shownLevelId = currentLevelIdAsync.value;
    final AsyncValue<CourseContentIndex> contentAsync;
    if (currentLevelIdAsync.hasError) {
      contentAsync = AsyncValue.error(
        currentLevelIdAsync.error!,
        currentLevelIdAsync.stackTrace!,
      );
    } else if (shownLevelId != null) {
      contentAsync = ref.watch(courseContentProvider(shownLevelId));
    } else {
      contentAsync = const AsyncValue.loading();
    }

    void onSelect(LevelCatalogEntry entry, LevelAccess levelAccess) {
      switch (levelAccess) {
        case LevelAccess.open:
          unawaited(
            ref
                .read(levelSelectionControllerProvider.notifier)
                .select(entry.levelId),
          );
          return;
        case LevelAccess.lockedNeedsPrerequisite:
        case LevelAccess.notReleased:
          // Task 8: the lock sheet explaining why this level isn't open.
          return;
        case LevelAccess.noContent:
          // Unreachable in practice — LevelStrip never makes a no-content
          // pill tappable — kept so this switch stays exhaustive.
          return;
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (index) => _CourseBody(
            index: index,
            unitProgress: unitProgress,
            lessonProgress: lessonProgress,
            catalog: catalog,
            shownLevelId: shownLevelId!,
            access: access,
            onSelect: onSelect,
          ),
        ),
      ),
    );
  }
}

class _CourseBody extends StatelessWidget {
  const _CourseBody({
    required this.index,
    required this.unitProgress,
    required this.lessonProgress,
    required this.catalog,
    required this.shownLevelId,
    required this.access,
    required this.onSelect,
  });

  final CourseContentIndex index;
  final List<UnitProgressData> unitProgress;
  final List<LessonProgressData> lessonProgress;
  final List<LevelCatalogEntry> catalog;
  final String shownLevelId;
  final Map<String, LevelAccess> access;
  final void Function(LevelCatalogEntry entry, LevelAccess access) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final units = index.bundle.units;
    final stateByUnitId = {
      for (final p in unitProgress) p.unitId: ProgressState.fromRaw(p.state),
    };
    final masteredIds = {
      for (final entry in stateByUnitId.entries)
        if (entry.value == ProgressState.mastered) entry.key,
    };
    final currentId = currentUnitId(
      units: units,
      masteredUnitIds: masteredIds,
      allLessonProgress: lessonProgress,
    );
    final lessonCount = units.fold<int>(0, (n, u) => n + u.lessons.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
      ),
      children: [
        Text(
          l10n.learnCourseOverline.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xxs),
        LevelStrip(
          catalog: catalog,
          shownLevelId: shownLevelId,
          access: access,
          onSelect: onSelect,
        ),
        const SizedBox(height: AppSpace.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            index.bundle.course.title,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            index.bundle.course.titleAr,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _CourseProgressCard(
          units: units,
          masteredIds: masteredIds,
          currentId: currentId,
          lessonCount: lessonCount,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.learnUnitsTitle.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        for (var i = 0; i < units.length; i++)
          _UnitRow(
            unit: units[i],
            number: i + 1,
            state: stateByUnitId[units[i].id] ?? ProgressState.notStarted,
            isCurrent: units[i].id == currentId,
            isFirst: i == 0,
            unitLessonProgress: [
              for (final p in lessonProgress)
                if (p.unitId == units[i].id) p,
            ],
          ),
        PathRow(
          isLast: true,
          node: PathNode(
            kind: PathNodeKind.flag,
            semanticsLabel: l10n.learnFinishOverline,
          ),
          child: _FinishCard(onTap: () => context.go('/tests')),
        ),
      ],
    );
  }
}

/// Units mastered over total, the course's lesson count, and one segment
/// per unit — green when mastered, ink for where the learner is.
class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({
    required this.units,
    required this.masteredIds,
    required this.currentId,
    required this.lessonCount,
  });

  final List<Unit> units;
  final Set<String> masteredIds;
  final String? currentId;
  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final success = theme.extension<FeedbackTheme>()!.success;
    final l10n = AppLocalizations.of(context)!;
    final track = Color.lerp(tokens.border, tokens.textSecondary, 0.15)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeLevelProgressCaption(
                      masteredIds.length,
                      units.length,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                Text(
                  l10n.learnLessonCount(lessonCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < units.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: masteredIds.contains(units[i].id)
                              ? success
                              : units[i].id == currentId
                              ? tokens.primaryInk
                              : track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.number,
    required this.state,
    required this.isCurrent,
    required this.isFirst,
    required this.unitLessonProgress,
  });

  final Unit unit;
  final int number;
  final ProgressState state;
  final bool isCurrent;
  final bool isFirst;
  final List<LessonProgressData> unitLessonProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stateLabel = switch (state) {
      ProgressState.mastered => l10n.unitStateMastered,
      ProgressState.needsReview => l10n.unitStateNeedsReview,
      ProgressState.inProgress => l10n.unitStateInProgress,
      ProgressState.notStarted => l10n.unitStateNotStarted,
    };
    final kind = state == ProgressState.mastered
        ? PathNodeKind.done
        : isCurrent
        ? PathNodeKind.current
        : PathNodeKind.upcoming;
    void openUnit() => context.go('/learn/unit/${unit.id}');

    return PathRow(
      isFirst: isFirst,
      onTap: isCurrent ? null : openUnit,
      node: PathNode(
        kind: kind,
        number: number,
        semanticsLabel: l10n.learnUnitNodeSemantics(number, stateLabel),
      ),
      child: isCurrent
          ? _CurrentUnitCard(
              unit: unit,
              number: number,
              unitLessonProgress: unitLessonProgress,
              onOpenUnit: openUnit,
            )
          : _UnitSummary(
              unit: unit,
              state: state,
              lessonsDone: _lessonsDone(unit, unitLessonProgress),
            ),
    );
  }
}

/// Lessons in [unit] played through to their last activity — the same
/// "finished" test the lesson player and `lessonResumeFor` use.
int _lessonsDone(Unit unit, List<LessonProgressData> unitLessonProgress) {
  final lastByLesson = {
    for (final p in unitLessonProgress) p.lessonId: p.lastActivityId,
  };
  return unit.lessons
      .where(
        (l) =>
            l.activities.isNotEmpty &&
            lastByLesson[l.id] == l.activities.last.id,
      )
      .length;
}

class _UnitTitle extends StatelessWidget {
  const _UnitTitle({required this.unit, this.large = false});

  final Unit unit;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xxs,
          children: [
            Text(
              unit.title,
              textDirection: TextDirection.ltr,
              style:
                  (large
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleMedium)
                      ?.copyWith(color: tokens.textPrimary),
            ),
            if (unit.levelRole == 'prerequisite')
              _Tag(
                label: l10n.learnUnitStarter.toUpperCase(),
                background: tokens.cardMuted,
                foreground: tokens.textSecondary,
              ),
          ],
        ),
        Text(
          unit.titleAr,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _UnitSummary extends StatelessWidget {
  const _UnitSummary({
    required this.unit,
    required this.state,
    required this.lessonsDone,
  });

  final Unit unit;
  final ProgressState state;
  final int lessonsDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );
    final minutes = unit.estimatedMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UnitTitle(unit: unit),
        const SizedBox(height: AppSpace.xxs),
        switch (state) {
          ProgressState.mastered => _Tag(
            icon: Icons.check_rounded,
            label: l10n.unitStateMastered,
            background: feedback.successContainer,
            foreground: feedback.onSuccessContainer,
          ),
          ProgressState.needsReview => _Tag(
            icon: Icons.refresh_rounded,
            label: l10n.unitStateNeedsReview,
            background: tokens.cardMuted,
            foreground: tokens.textPrimary,
          ),
          _ when lessonsDone > 0 => Text(
            l10n.learnUnitLessonsDone(lessonsDone, unit.lessons.length),
            style: meta,
          ),
          _ => Text(
            minutes.length == 2
                ? '${l10n.learnLessonCount(unit.lessons.length)} · '
                      '${l10n.learnUnitMinutes(minutes[0], minutes[1])}'
                : l10n.learnLessonCount(unit.lessons.length),
            style: meta,
          ),
        },
      ],
    );
  }
}

/// The one emphasised card on the path: the unit the learner is working
/// on, how far through its lessons they are, the next lesson, and a button
/// straight into it (or into the unit page once every lesson is played but
/// the unit isn't mastered yet). Tapping the card itself opens the unit.
class _CurrentUnitCard extends StatelessWidget {
  const _CurrentUnitCard({
    required this.unit,
    required this.number,
    required this.unitLessonProgress,
    required this.onOpenUnit,
  });

  final Unit unit;
  final int number;
  final List<LessonProgressData> unitLessonProgress;
  final VoidCallback onOpenUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final done = _lessonsDone(unit, unitLessonProgress);
    final total = unit.lessons.length;
    final resume = lessonResumeFor(
      unit: unit,
      unitLessonProgress: unitLessonProgress,
    );
    final started = unitLessonProgress.isNotEmpty;
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );

    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.primaryInk, width: 2),
      ),
      child: InkWell(
        onTap: onOpenUnit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (started
                        ? l10n.learnUnitInProgressOverline(number)
                        : l10n.learnUnitStartHereOverline(number))
                    .toUpperCase(),
                style: overlineStyle(context, color: tokens.primaryInk),
              ),
              const SizedBox(height: AppSpace.xxs),
              _UnitTitle(unit: unit, large: true),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.learnUnitLessonsDone(done, total),
                      style: meta,
                    ),
                  ),
                  Text(
                    l10n.homeLessonPercent(
                      total == 0 ? 0 : (done * 100 / total).round(),
                    ),
                    style: meta,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs - 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  color: tokens.primaryInk,
                  backgroundColor: Color.lerp(
                    tokens.border,
                    tokens.textSecondary,
                    0.15,
                  ),
                ),
              ),
              if (resume != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  l10n.homeJourneyNext('\u2068${resume.lesson.title}\u2069'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              FilledButton(
                onPressed: resume == null
                    ? onOpenUnit
                    : () => context.push(
                        '/lesson-player/${unit.id}/${resume.lesson.id}',
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        resume == null
                            ? l10n.homeOpenUnitCta
                            : resume.activitiesDone == 0
                            ? l10n.homeStartLessonCta
                            : l10n.homeContinueLessonCta,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishCard extends StatelessWidget {
  const _FinishCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.learnFinishOverline.toUpperCase(),
                      style: overlineStyle(
                        context,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.learnFinishTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.learnFinishBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
