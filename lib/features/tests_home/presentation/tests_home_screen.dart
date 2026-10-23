import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/widgets/error_state_view.dart';
import '../../../content/index/course_content_index.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/local/database.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../placement_test/domain/placement_outcome.dart';
import '../../placement_test/domain/placement_plan.dart';
import '../../placement_test/providers/placement_providers.dart';
import '../../progress/providers/level_providers.dart';
import '../providers/tests_home_providers.dart';

/// The Tests tab.
///
/// A brand-new learner (no placement attempt, no lesson played) is pointed
/// at the placement test with one highlighted card. Otherwise placement is
/// a row showing when it was taken and its result ("start from Unit 4").
/// Then "Finish A2" — or whichever level the learner is in: units mastered
/// with a segment per unit, and the final mission and final assessment with
/// their real size and time and their latest result. Unit checks aren't a
/// separate flow — a closing note points to each unit's mission on the Learn
/// tab. Every test stays open (free access, docs/PRODUCT.md flow 5); course
/// progress only advises when.
///
/// Everything but placement follows the level the learner is in
/// ([currentCourseProvider]), so an A2 learner's exit is A2's mission and
/// A2's assessment — see docs/superpowers/specs/2026-09-19-a2-level-design.md.
/// The placement test is deliberately level-agnostic: it covers every
/// released level and finds where the learner belongs, so it neither reads
/// nor names the current one.
class TestsHomeScreen extends ConsumerWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(currentCourseProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: courseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              ErrorStateView(error: error, stackTrace: stackTrace),
          data: (course) =>
              _TestsBody(index: course.index, levelCode: course.cefrCode),
        ),
      ),
    );
  }
}

class _TestsBody extends ConsumerWidget {
  const _TestsBody({required this.index, required this.levelCode});

  final CourseContentIndex index;

  /// The CEFR code of the level [index] holds, for the copy that names it.
  final String levelCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final placementAsync = ref.watch(latestPlacementAttemptProvider);
    final mission = ref.watch(latestFinalMissionAttemptProvider).value;
    final assessment = ref.watch(latestFinalAssessmentAttemptProvider).value;
    final lessonsAsync = ref.watch(allLessonProgressProvider);
    final unitProgress = ref.watch(allUnitProgressProvider).value ?? const [];

    final placement = placementAsync.value;
    final isNewLearner =
        placementAsync.hasValue &&
        lessonsAsync.hasValue &&
        placement == null &&
        lessonsAsync.value!.isEmpty;
    final units = index.bundle.units;
    // A placement result is numbered against the level its recommended
    // unit id names — never against whichever level the learner is in now,
    // where the other level's unit ids resolve to nothing and the row once
    // read "Unit 0". The plan holds every released level for exactly this.
    final placementPlan = ref.watch(placementPlanProvider).value;
    final masteredIds = {
      for (final p in unitProgress)
        if (p.state == 'mastered') p.unitId,
    };
    final fm = index.bundle.finalMission;
    final fa = index.bundle.finalAssessment;
    final faQuestions = fa.sections.values.fold<int>(
      0,
      (n, s) => n + s.activities.length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
      ),
      children: [
        Text(
          l10n.navTests,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          l10n.testsHubSubtitle(levelCode),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        if (isNewLearner) ...[
          const SizedBox(height: AppSpace.md),
          const _PlacementHero(),
        ] else if (placementAsync.hasValue) ...[
          SectionHeading(l10n.testsPlacementOverline),
          _RowsCard(
            rows: [
              _TestRow(
                icon: Icons.flag_outlined,
                title: l10n.testsPlacementTitle,
                body: placement?.completedAt == null
                    ? l10n.testsPlacementHeroBody
                    : l10n.testsTakenOn(
                        _date(context, placement!.completedAt!),
                      ),
                status: _placementPill(l10n, placement, placementPlan),
                onTap: () => context.push('/tests/placement'),
              ),
            ],
          ),
        ],
        SectionHeading(l10n.testsFinishOverline(levelCode)),
        _CourseProgress(
          mastered: units.where((u) => masteredIds.contains(u.id)).length,
          segments: [for (final u in units) masteredIds.contains(u.id)],
        ),
        const SizedBox(height: AppSpace.xs),
        _RowsCard(
          rows: [
            _TestRow(
              icon: Icons.explore_outlined,
              title: fm.title,
              titleAr: fm.titleAr,
              body: l10n.testsMissionBody(levelCode),
              meta: fm.estimatedMinutes.length == 2
                  ? l10n.testsMissionMeta(
                      fm.activities.length,
                      fm.stages.length,
                      fm.estimatedMinutes[0],
                      fm.estimatedMinutes[1],
                    )
                  : null,
              status: _missionPill(l10n, mission),
              onTap: () => context.push('/tests/final-mission'),
            ),
            _TestRow(
              icon: Icons.fact_check_outlined,
              title: fa.title,
              titleAr: fa.titleAr,
              body: l10n.testsAssessmentBody,
              meta: fa.estimatedMinutes.length == 2
                  ? l10n.testsAssessmentMeta(
                      faQuestions,
                      fa.sections.length,
                      fa.estimatedMinutes[0],
                      fa.estimatedMinutes[1],
                    )
                  : null,
              status: _assessmentPill(l10n, assessment),
              onTap: () => context.push('/tests/final-assessment'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.testsUnitChecksNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  String _date(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
          .format(date);

  /// A finished placement attempt's result, read back from what was
  /// stored — including results recorded before the test covered more than
  /// one level, which a learner should still be able to read in their
  /// history. `a1Mastered` is such a row, and stays exactly as readable as
  /// today's `a2Mastered`.
  StatusPill _placementPill(
    AppLocalizations l10n,
    PlacementAttempt? a,
    PlacementPlan? plan,
  ) {
    if (a == null) return StatusPill(label: l10n.testsNotTaken);
    if (a.completedAt == null) return StatusPill(label: l10n.testsNotFinished);
    final outcome = a.outcome;
    final masteredLevelId = outcome == null
        ? null
        : masteredLevelIdOfStoredOutcome(outcome);
    String? result;
    if (masteredLevelId != null) {
      final level = plan?.levels
          .where((l) => l.levelId == masteredLevelId)
          .firstOrNull;
      result = l10n.testsPlacementResultMastered(
        level?.cefrCode ?? masteredLevelId.toUpperCase(),
      );
    } else {
      // The two outcomes that name a unit the row itself may not carry:
      // the oldest stored rows recorded the outcome alone.
      final unitId =
          a.recommendedUnitId ??
          switch (outcome) {
            'startWithEssentials' => 'A1-U0',
            'startA1FromU1' => 'A1-U1',
            _ => null,
          };
      final unit = placementUnitRefIn(plan, unitId);
      if (unit != null) {
        result = l10n.testsPlacementResultUnit(unit.cefrCode, unit.number);
      }
    }
    return StatusPill(
      label: result ?? l10n.testsNotFinished,
      tone: StatusTone.success,
      icon: Icons.flag_rounded,
    );
  }

  StatusPill _missionPill(AppLocalizations l10n, FinalMissionAttempt? a) {
    if (a == null) return StatusPill(label: l10n.testsNotTaken);
    if (a.completedAt == null) return StatusPill(label: l10n.testsNotFinished);
    return a.outcome == 'passed'
        ? StatusPill(
            label: l10n.testsPassed,
            tone: StatusTone.success,
            icon: Icons.check_rounded,
          )
        : StatusPill(
            label: l10n.testsNotPassedYet,
            tone: StatusTone.attention,
            icon: Icons.refresh_rounded,
          );
  }

  StatusPill _assessmentPill(AppLocalizations l10n, FinalAssessmentAttempt? a) {
    if (a == null) return StatusPill(label: l10n.testsNotTaken);
    if (a.completedAt == null) return StatusPill(label: l10n.testsNotFinished);
    final sections = a.sectionResults == null
        ? const <dynamic>[]
        : jsonDecode(a.sectionResults!) as List<dynamic>;
    final passed = sections
        .where((s) => (s as Map<String, dynamic>)['status'] == 'passed')
        .length;
    final overall = a.outcomeSummary == null
        ? false
        : (jsonDecode(a.outcomeSummary!)
                  as Map<String, dynamic>)['overallPassed'] ==
              true;
    return StatusPill(
      label: l10n.testsSkillsPassed(passed, sections.length),
      tone: overall ? StatusTone.success : StatusTone.attention,
      icon: overall ? Icons.check_rounded : Icons.refresh_rounded,
    );
  }
}

/// The brand-new learner's one highlighted card: find your starting point.
class _PlacementHero extends StatelessWidget {
  const _PlacementHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.primaryInk, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.testsStartHereOverline.toUpperCase(),
              style: overlineStyle(context, color: tokens.primaryInk),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              l10n.testsPlacementHeroTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              l10n.testsPlacementHeroBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.testsPlacementMeta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.push('/tests/placement'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(l10n.testsPlacementCta)),
                  const SizedBox(width: AppSpace.xs),
                  // arrow_forward mirrors itself in right-to-left layouts.
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "N of 13 units mastered — best taken when…" over a segment per unit.
class _CourseProgress extends StatelessWidget {
  const _CourseProgress({required this.mastered, required this.segments});

  final int mastered;
  final List<bool> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final total = segments.length;
    final track = Color.lerp(tokens.border, tokens.textSecondary, 0.15)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mastered == total
                  ? l10n.testsFinishReady(total)
                  : l10n.testsFinishProgress(mastered, total),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.sm - 2),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final (i, done) in segments.indexed) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: done ? feedback.success : track,
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

/// A hairline card of rows separated by dividers.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.border),
      ),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            row,
          ],
        ],
      ),
    );
  }
}

/// One test: an icon, its title (and Arabic), what it is, its size and
/// time, and its latest result; tapping opens it.
class _TestRow extends StatelessWidget {
  const _TestRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    required this.onTap,
    this.titleAr,
    this.meta,
  });

  final IconData icon;
  final String title;
  final String? titleAr;
  final String body;
  final String? meta;
  final Widget status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md - 2,
          AppSpace.md - 2,
          AppSpace.xs,
          AppSpace.md - 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: tokens.primaryInkTint,
                child: Icon(icon, size: 20, color: tokens.primaryInk),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (titleAr == null)
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    )
                  else
                    ContentText.en(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  if (titleAr != null)
                    ContentText.ar(
                      titleAr!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      meta!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: status,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
