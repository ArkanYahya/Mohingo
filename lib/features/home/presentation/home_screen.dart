import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/lesson_type_label.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/local/database.dart';
import '../../learning_path/domain/current_unit_selector.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/domain/level_access.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../review/providers/review_providers.dart';
import '../domain/day_part.dart';
import '../../learning_path/domain/lesson_resume.dart';
import 'widgets/continue_lesson_card.dart';
import 'widgets/daily_goal_section.dart';
import 'widgets/home_header.dart';
import 'widgets/journey_card.dart';
import 'widgets/next_level_card.dart';
import 'widgets/review_status.dart';

/// Home: where am I, what should I do now, how am I doing.
///
/// Reading order follows priority — header (greeting, level, streak), the
/// continue-lesson hero (the one primary action), today's goal, the level
/// journey, then review status. Review moves up beside today's goal and
/// becomes a card only when something is actually due. All state comes
/// from existing providers; this screen only arranges it. See
/// docs/DESIGN_SYSTEM.md.
///
/// Everything here follows the level the learner is in
/// ([currentCourseProvider]), so an A2 learner opens the app to A2's
/// continue card, A2's journey and A2 by name. Once that level's units are
/// all mastered and the level after it is open, the one thing Home adds is
/// an offer to start it — a card the learner taps, never an automatic
/// switch (docs/superpowers/specs/2026-09-19-a2-level-design.md, Design 3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(currentCourseProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: courseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (course) => _HomeBody(course: course),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.course});

  final CurrentCourse course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final index = course.index;
    final levelCode = course.cefrCode;

    final unitProgress = ref.watch(allUnitProgressProvider).value ?? const [];
    final lessonProgress =
        ref.watch(allLessonProgressProvider).value ?? const [];
    final streakDays = ref.watch(currentStreakDaysProvider).value ?? 0;
    final dueCount = ref.watch(dueVocabularyCountProvider).value ?? 0;
    final taskCounts =
        ref.watch(dailyTaskCountsProvider).value ??
        (lesson: 0, vocabularyReview: 0, speaking: 0);
    final learnerName = ref.watch(currentLearnerProvider).value?.name?.trim();

    final units = index.bundle.units;
    final masteredUnitIds = <String>{
      for (final p in unitProgress)
        if (p.state == 'mastered') p.unitId,
    };
    final currentId = currentUnitId(
      units: units,
      masteredUnitIds: masteredUnitIds,
      allLessonProgress: lessonProgress,
    );
    final currentUnit = currentId == null ? null : index.unitsById[currentId];
    final currentPosition = currentUnit == null
        ? null
        : units.indexOf(currentUnit);

    String unitTitle(Unit unit) =>
        _isolate(isArabic ? unit.titleAr : unit.title);

    void resume(Unit unit, LessonResume? lessonResume) {
      if (lessonResume != null) {
        context.push('/lesson-player/${unit.id}/${lessonResume.lesson.id}');
      } else {
        context.go('/learn/unit/${unit.id}');
      }
    }

    final hero = _hero(
      context,
      l10n,
      levelCode: levelCode,
      unit: currentUnit,
      position: currentPosition,
      lessonProgress: lessonProgress,
      onResume: resume,
    );

    // The level that builds on this one, offered only once this one's units
    // are all mastered and that one is genuinely open — the same two
    // questions the Learn tab's lock asks, answered by the same code. The
    // offer is a tap, never a switch Home makes on the learner's behalf.
    final next = nextLevelEntryIn(
      ref.watch(levelCatalogProvider),
      course.levelId,
    );
    final nextAccess = next == null
        ? null
        : ref.watch(levelAccessProvider(next.levelId)).value;
    final nextLevelOffer =
        next != null &&
            nextAccess == LevelAccess.open &&
            levelComplete(units: units, masteredUnitIds: masteredUnitIds)
        ? NextLevelCard(
            currentLevelCode: levelCode,
            nextLevelCode: next.cefrCode,
            onStart: () => unawaited(
              ref
                  .read(levelSelectionControllerProvider.notifier)
                  .select(next.levelId),
            ),
          )
        : null;

    final goals = DailyGoalSection(
      goals: [
        DailyGoal(
          icon: Icons.menu_book_outlined,
          label: l10n.homeTaskFinishLesson,
          done: taskCounts.lesson,
          target: 1,
        ),
        DailyGoal(
          icon: Icons.style_outlined,
          label: l10n.homeTaskReviewWords,
          done: taskCounts.vocabularyReview,
          target: 5,
        ),
        DailyGoal(
          icon: Icons.mic_none_rounded,
          label: l10n.homeTaskSpeakOnce,
          done: taskCounts.speaking,
          target: 1,
        ),
      ],
    );

    final journey = JourneyCard(
      steps: [
        for (final unit in units)
          masteredUnitIds.contains(unit.id)
              ? JourneyStep.mastered
              : unit.id == currentId
              ? JourneyStep.current
              : JourneyStep.ahead,
      ],
      position: currentPosition == null ? null : currentPosition + 1,
      nowTitle: currentUnit == null
          ? l10n.homeAllUnitsMastered(levelCode)
          : l10n.homeJourneyNow(unitTitle(currentUnit)),
      nextTitle: currentPosition == null
          ? null
          : l10n.homeJourneyNext(
              currentPosition + 1 < units.length
                  ? unitTitle(units[currentPosition + 1])
                  : l10n.learnFinishTitle,
            ),
      onTap: () => context.go('/learn'),
    );

    final review = ReviewStatus(
      dueCount: dueCount,
      onReview: () => context.go('/review'),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        AppSpace.lg,
      ),
      children: [
        HomeHeader(
          dayPart: dayPartFor(DateTime.now().hour),
          name: (learnerName?.isEmpty ?? true) ? null : learnerName,
          levelCode: levelCode,
          streakDays: streakDays,
        ),
        const SizedBox(height: AppSpace.lg),
        hero,
        if (nextLevelOffer != null) ...[
          const SizedBox(height: AppSpace.sm),
          nextLevelOffer,
        ],
        const SizedBox(height: AppSpace.md),
        goals,
        if (dueCount > 0) ...[const SizedBox(height: AppSpace.md), review],
        const SizedBox(height: AppSpace.md),
        journey,
        if (dueCount <= 0) ...[const SizedBox(height: AppSpace.xs), review],
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    AppLocalizations l10n, {
    required String levelCode,
    required Unit? unit,
    required int? position,
    required List<LessonProgressData> lessonProgress,
    required void Function(Unit, LessonResume?) onResume,
  }) {
    if (unit == null || position == null) {
      return ContinueLessonCard(
        badge: const Icon(Icons.emoji_events_rounded),
        overline: levelCode,
        title: l10n.homeAllUnitsMastered(levelCode),
        ctaLabel: l10n.navTests,
        onPressed: () => context.go('/tests'),
      );
    }

    final lessonResume = lessonResumeFor(
      unit: unit,
      unitLessonProgress: [
        for (final row in lessonProgress)
          if (row.unitId == unit.id) row,
      ],
    );
    if (lessonResume == null) {
      return ContinueLessonCard(
        badge: const Icon(Icons.replay_rounded),
        overline: l10n.homeUnitReviewOverline(position + 1),
        title: unit.title,
        titleAr: unit.titleAr,
        body: l10n.homeUnitAllLessonsDone,
        ctaLabel: l10n.homeOpenUnitCta,
        onPressed: () => onResume(unit, null),
      );
    }

    final lesson = lessonResume.lesson;
    final started = lessonResume.activitiesDone > 0;
    final type = lessonTypeLabel(l10n, lesson.lessonType);
    final count = l10n.homeActivityCount(lessonResume.activityCount);
    return ContinueLessonCard(
      badge: Text('${lessonResume.lessonIndex + 1}'),
      overline: l10n.homeUnitLessonOverline(
        position + 1,
        lessonResume.lessonIndex + 1,
      ),
      title: lesson.title,
      titleAr: lesson.titleAr,
      meta: type == null ? count : '$type · $count',
      progress: lessonResume.fraction,
      progressLabel: l10n.homeLessonProgressLabel,
      progressValueLabel: started
          ? l10n.homeLessonPercent((lessonResume.fraction * 100).round())
          : l10n.homeLessonNew,
      ctaLabel: started ? l10n.homeContinueLessonCta : l10n.homeStartLessonCta,
      onPressed: () => onResume(unit, lessonResume),
    );
  }
}

/// Wraps a curriculum title in Unicode first-strong isolates so an English
/// title embedded in an Arabic sentence (or vice versa) keeps its own
/// direction — trailing punctuation like "Hello, I'm…" stays put.
String _isolate(String s) => '\u2068$s\u2069';
