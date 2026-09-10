import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../learning_path/domain/current_unit_selector.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/domain/repositories/daily_task_event_repository.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../review/providers/review_providers.dart';

/// Home tab landing screen: a streak card, the "Continue learning" card, an
/// A1 level-progress card, and a review-due card. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);
    final lessonProgressAsync = ref.watch(allLessonProgressProvider);
    final streakAsync = ref.watch(currentStreakDaysProvider);
    final dueCountAsync = ref.watch(dueVocabularyCountProvider);
    final taskCountsAsync = ref.watch(dailyTaskCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final masteredUnitIds = <String>{
            for (final p in progressAsync.value ?? const [])
              if (p.state == 'mastered') p.unitId,
          };
          final totalUnits = index.bundle.units.length;
          final masteredCount = masteredUnitIds.length;
          final currentUnit = currentUnitId(
            units: index.bundle.units,
            masteredUnitIds: masteredUnitIds,
            allLessonProgress: lessonProgressAsync.value ?? const [],
          );
          final nextUnit = currentUnit == null
              ? null
              : index.unitsById[currentUnit];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StreakCard(days: streakAsync.value ?? 0),
              const SizedBox(height: 12),
              _TasksTodayRow(
                counts:
                    taskCountsAsync.value ??
                    (lesson: 0, vocabularyReview: 0, speaking: 0),
              ),
              const SizedBox(height: 12),
              if (nextUnit == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.homeAllUnitsMastered),
                  ),
                )
              else
                _ContinueLearningCard(
                  title: nextUnit.title,
                  titleAr: nextUnit.titleAr,
                  onContinue: () => context.go('/learn/a1/unit/${nextUnit.id}'),
                ),
              const SizedBox(height: 12),
              _LevelProgressCard(mastered: masteredCount, total: totalUnits),
              const SizedBox(height: 12),
              _ReviewDueCard(
                count: dueCountAsync.value ?? 0,
                onTap: () => context.go('/review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gamification = Theme.of(context).extension<GamificationTheme>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: gamification.streakAccent,
              child: Text(
                '$days',
                style: TextStyle(
                  // Not colorScheme.onPrimary — that is white in the light
                  // theme and only 3.64:1 on this ground. See
                  // [GamificationTheme.onStreakAccent].
                  color: gamification.onStreakAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeStreakTitle(days),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.homeStreakEncouragement,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.title,
    required this.titleAr,
    required this.onContinue,
  });

  final String title;
  final String titleAr;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // A full-bleed vivid fill, not the paler primaryContainer — this is
    // Home's one "hero" element, and the "full energy" redesign direction
    // asked for it to read as vivid, not calm-and-muted like an ordinary
    // card. See docs/DESIGN_SYSTEM.md.
    return Card(
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.continueLearningTitle,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colorScheme.onPrimary),
            ),
            Text(
              titleAr,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
              ),
              onPressed: onContinue,
              child: Text(l10n.continueLearningCta),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 3 daily-task tiles ("Finish a lesson", "Review 5 words", "Speak
/// once") — each fills with the brand accent until its target is reached
/// today, then turns [FeedbackTheme.success] (the same semantic green a
/// correct answer uses), regardless of colour theme. See
/// docs/DESIGN_SYSTEM.md.
class _TasksTodayRow extends StatelessWidget {
  const _TasksTodayRow({required this.counts});

  final DailyTaskCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeTasksTodayTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        // IntrinsicHeight, not Row(crossAxisAlignment: stretch) — this Row
        // sits in unbounded-height ListView context, and `stretch` there
        // asks the flex children for infinite height (a real crash, not
        // just a lint). IntrinsicHeight measures the tallest tile first,
        // giving every tile that same finite height instead.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TaskTile(
                  icon: Icons.menu_book_outlined,
                  label: l10n.homeTaskFinishLesson,
                  done: counts.lesson,
                  target: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskTile(
                  icon: Icons.style_outlined,
                  label: l10n.homeTaskReviewWords,
                  done: counts.vocabularyReview,
                  target: 5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskTile(
                  icon: Icons.mic_none,
                  label: l10n.homeTaskSpeakOnce,
                  done: counts.speaking,
                  target: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.icon,
    required this.label,
    required this.done,
    required this.target,
  });

  final IconData icon;
  final String label;
  final int done;
  final int target;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    final complete = done >= target;
    final fill = complete ? feedbackTheme.success : colorScheme.primary;
    final onFill = complete ? feedbackTheme.onSuccess : colorScheme.onPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: onFill, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${done.clamp(0, target)}/$target',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: onFill, fontWeight: FontWeight.bold),
              ),
              Icon(complete ? Icons.check : icon, color: onFill, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.mastered, required this.total});

  final int mastered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : mastered / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeLevelProgressTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeLevelProgressCaption(mastered, total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDueCard extends StatelessWidget {
  const _ReviewDueCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.style_outlined),
        title: Text(l10n.homeReviewDueTitle(count)),
        onTap: onTap,
      ),
    );
  }
}
