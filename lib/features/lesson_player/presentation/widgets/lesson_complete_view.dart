import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../content/models/curriculum_structure.dart';
import '../../../../content/models/domain_definitions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/lesson_type_label.dart';
import '../../../../core/l10n/skill_label.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';
import '../../../../core/theme/gamification_theme_extension.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../../core/widgets/content_text.dart';
import '../../../activity_engine/domain/activity_submission.dart';
import 'activity_eyebrow.dart';
import 'lesson_intro_chrome.dart';
import 'lesson_top_bar.dart';

/// The end of a lesson: how it went, what it trained, and what's next.
///
/// A score ring (right answers over auto-graded ones, the arc animating in
/// on arrival), the lesson's title, three figures — streak, accuracy, and
/// the lesson's key phrases (or, without any, the questions answered) — a
/// line for answers saved for later review, the skills practised, and a
/// preview of the unit's next lesson. The bar offers the next lesson (or
/// "Back to unit" after the last one) and "Review answers".
///
/// Answers saved for review (`notAutoGraded`) never count toward the
/// ring or accuracy: when nothing was auto-graded the ring shows a check
/// and the accuracy figure is left out, rather than showing a misleading 0%.
class LessonCompleteView extends StatelessWidget {
  const LessonCompleteView({
    required this.lesson,
    required this.results,
    required this.skills,
    required this.phraseCount,
    required this.streakDays,
    this.nextLesson,
    this.nextLessonNumber,
    required this.onNext,
    required this.onReviewAnswers,
    required this.onClose,
    this.progress,
    super.key,
  });

  final Lesson lesson;

  /// This session's graded outcomes, one per answered activity.
  final List<ActivityCorrectness> results;

  /// The skills of the activities answered this session, in order.
  final List<Skill> skills;
  final int phraseCount;

  /// Null until the streak has loaded.
  final int? streakDays;
  final Lesson? nextLesson;
  final int? nextLessonNumber;
  final VoidCallback onNext;
  final VoidCallback onReviewAnswers;
  final VoidCallback onClose;

  /// The lesson player's progress bar, shown full in the top bar.
  final Widget? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    final correct = results
        .where((r) => r == ActivityCorrectness.correct)
        .length;
    final scored =
        correct +
        results.where((r) => r == ActivityCorrectness.incorrect).length;
    final pending = results.length - scored;
    final practised = <String, Skill>{
      for (final skill in skills) learnerSkillLabel(l10n, skill): skill,
    };

    return Column(
      children: [
        LessonTopBar(onClose: onClose, progress: progress ?? const SizedBox()),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _ScoreRing(correct: correct, scored: scored),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  l10n.lessonCompleteTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  lesson.title,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                Text(
                  lesson.titleAr,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                _Figures(
                  figures: [
                    (
                      icon: Icons.local_fire_department_rounded,
                      color: theme.extension<GamificationTheme>()!.streakAccent,
                      value: streakDays == null
                          ? '–'
                          : l10n.homeStreakChip(streakDays!),
                      label: l10n.lessonCompleteStreakLabel,
                    ),
                    if (scored > 0)
                      (
                        icon: Icons.track_changes_rounded,
                        color: tokens.primaryInk,
                        value: l10n.homeLessonPercent(
                          (correct * 100 / scored).round(),
                        ),
                        label: l10n.lessonCompleteAccuracyLabel,
                      ),
                    phraseCount > 0
                        ? (
                            icon: Icons.forum_outlined,
                            color: tokens.primaryInk,
                            value: '$phraseCount',
                            label: l10n.lessonCompletePhrasesLabel,
                          )
                        : (
                            icon: Icons.quiz_outlined,
                            color: tokens.primaryInk,
                            value: '${results.length}',
                            label: l10n.lessonCompleteQuestionsLabel,
                          ),
                  ],
                ),
                if (pending > 0) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                      const SizedBox(width: AppSpace.xs - 2),
                      Flexible(
                        child: Text(
                          l10n.lessonCompletePendingReview(pending),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (practised.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    l10n.lessonCompleteSkillsTitle.toUpperCase(),
                    style: overlineStyle(context, color: tokens.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      for (final entry in practised.entries)
                        _SkillChip(
                          label: entry.key,
                          icon: skillIcon(entry.value),
                        ),
                    ],
                  ),
                ],
                if (nextLesson != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  _UpNextCard(
                    lesson: nextLesson!,
                    number: nextLessonNumber ?? 0,
                    onTap: onNext,
                  ),
                ],
              ],
            ),
          ),
        ),
        LessonActionBar(
          label: nextLesson != null
              ? l10n.lessonCompleteNextLesson
              : l10n.lessonCompleteBackToUnit,
          showArrow: nextLesson != null,
          onPressed: onNext,
          secondary: TextButton(
            onPressed: onReviewAnswers,
            child: Text(l10n.lessonCompleteReviewAnswers),
          ),
        ),
      ],
    );
  }
}

/// 128px ring: the arc is right answers over auto-graded ones, in the
/// semantic success green, sweeping in over 900ms (instant under reduce
/// motion). With nothing auto-graded it's a full ink ring around a check.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.correct, required this.scored});

  final int correct;
  final int scored;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final success = theme.extension<FeedbackTheme>()!.success;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final graded = scored > 0;
    final target = graded ? correct / scored : 1.0;
    final track = Color.lerp(tokens.border, tokens.textSecondary, 0.15)!;

    return Semantics(
      label: graded ? l10n.lessonCompleteTally(correct, scored) : null,
      child: ExcludeSemantics(
        excluding: graded,
        child: SizedBox.square(
          dimension: 128,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: target),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => CustomPaint(
              painter: _RingPainter(
                value: value,
                track: track,
                arc: graded ? success : tokens.primaryInk,
              ),
              child: child,
            ),
            // Scales down rather than overflow the ring at large text.
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: graded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$correct/$scored',
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontSize: 28,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            l10n.lessonCompleteCorrectCaption,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: tokens.primaryInk,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.arc});

  final double value;
  final Color track;
  final Color arc;

  static const double _stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      value != oldDelegate.value ||
      track != oldDelegate.track ||
      arc != oldDelegate.arc;
}

typedef _Figure = ({IconData icon, Color color, String value, String label});

/// Two or three figures side by side on one card, split by hairlines —
/// or, when the columns would be too narrow for the text size, stacked
/// one per row (icon, label, value) so no word breaks across lines.
class _Figures extends StatelessWidget {
  const _Figures({required this.figures});

  final List<_Figure> figures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final scaler = MediaQuery.textScalerOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / figures.length;
          if (columnWidth >= scaler.scale(72)) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < figures.length; i++) ...[
                    if (i > 0) VerticalDivider(width: 1, color: tokens.border),
                    Expanded(child: _FigureColumn(figure: figures[i])),
                  ],
                ],
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < figures.length; i++) ...[
                if (i > 0) Divider(height: 1, color: tokens.border),
                _FigureRow(figure: figures[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FigureColumn extends StatelessWidget {
  const _FigureColumn({required this.figure});

  final _Figure figure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.md,
        ),
        child: Column(
          children: [
            Icon(figure.icon, size: 22, color: figure.color),
            const SizedBox(height: AppSpace.xxs),
            Text(
              figure.value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            Text(
              figure.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({required this.figure});

  final _Figure figure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Icon(figure.icon, size: 22, color: figure.color),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                figure.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              figure.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs - 2,
      ),
      decoration: BoxDecoration(
        color: tokens.cardMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tokens.textSecondary),
          const SizedBox(width: AppSpace.xs - 2),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// The unit's next lesson: "UP NEXT · LESSON 2", its title and Arabic,
/// type and size. The whole card continues to it.
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.lesson,
    required this.number,
    required this.onTap,
  });

  final Lesson lesson;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final type = lessonTypeLabel(l10n, lesson.lessonType);
    final count = l10n.homeActivityCount(lesson.activities.length);

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
                      l10n.lessonCompleteUpNext(number).toUpperCase(),
                      style: overlineStyle(
                        context,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    ContentText.en(
                      lesson.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    ContentText.ar(
                      lesson.titleAr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      type == null ? count : '$type · $count',
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
