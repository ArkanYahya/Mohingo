import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/capstone.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/models/media_specification.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/status_pill.dart';
import '../../lesson_player/presentation/widgets/activity_eyebrow.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_intro_view.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/presentation/widgets/test_result_view.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../domain/final_mission_scoring.dart';

/// The current level's Final Mission — a scenario-based capstone reusing
/// the bundle's own `finalMission.activities` directly (no sampling needed,
/// unlike the placement test: this content is dedicated and pre-built).
/// Scored per [FinalMission.requiredSkillGroups] independently
/// (`noSingleAverageCompensation`), never one blended average.
///
/// Which level's mission this is follows [currentCourseProvider], so an A2
/// learner gets A2's — the Tests tab that opens it follows the same seam.
class FinalMissionScreen extends ConsumerWidget {
  const FinalMissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(currentCourseProvider);
    final learnerAsync = ref.watch(currentLearnerProvider);
    return courseAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (course) => learnerAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (error, _) => _ErrorScaffold(message: '$error'),
        data: (learner) => _FinalMissionBody(
          mission: course.index.bundle.finalMission,
          courseId: course.index.bundle.course.id,
          levelCode: course.cefrCode,
          mediaByKey: course.index.bundle.mediaSpecifications,
          learnerId: learner.id,
        ),
      ),
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

class _FinalMissionBody extends ConsumerStatefulWidget {
  const _FinalMissionBody({
    required this.mission,
    required this.courseId,
    required this.levelCode,
    required this.mediaByKey,
    required this.learnerId,
  });

  final FinalMission mission;
  final String courseId;

  /// The CEFR code of the level [mission] closes, for the copy naming it.
  final String levelCode;

  final Map<String, MediaSpecification> mediaByKey;
  final int learnerId;

  @override
  ConsumerState<_FinalMissionBody> createState() => _FinalMissionBodyState();
}

class _FinalMissionBodyState extends ConsumerState<_FinalMissionBody> {
  int? _attemptId;
  String? _sessionUuid;
  int _index = 0;

  /// The current answer's save, awaited before moving on — the feedback
  /// panel (and its Continue) appears as soon as Check is tapped.
  Future<void>? _recording;
  FinalMissionScoringResult? _result;
  final Map<String, List<double?>> _scoresBySkill = {};
  bool _started = false;
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    final repository = ref.read(assessmentAttemptRepositoryProvider);
    final attemptId = await repository.startFinalMissionAttempt(
      learnerId: widget.learnerId,
      courseId: widget.courseId,
    );
    final attemptRow = await repository.latestFinalMissionAttempt(
      learnerId: widget.learnerId,
      courseId: widget.courseId,
    );
    if (!mounted) return;
    setState(() {
      _attemptId = attemptId;
      _sessionUuid = attemptRow?.uuid;
      _started = true;
      _starting = false;
    });
  }

  Future<void> _handleSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    final evidenceSkill = resolveEvidenceSkill(activity, submission);
    // `form` activities are recorded below for progress/audit purposes but
    // never counted as scoring evidence: FormActivityView always submits
    // notAutoGraded (see its doc comment — multi-field form grading isn't
    // wired up), so a form activity's null score would otherwise permanently
    // stick its skill group's pendingReviewCount above zero and make the
    // mission un-passable regardless of every other answer. Every other
    // notAutoGraded submission (a still-unmigrated rubric, an unresolved
    // online refinement) still counts, so the honest pending-review signal
    // final_mission_scoring.dart documents is preserved for real gaps.
    // Counted before the save so the result can't miss it.
    if (activity is! FormActivity) {
      _scoresBySkill
          .putIfAbsent(evidenceSkill.name, () => [])
          .add(submission.score);
    }
    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: activity.id,
          sessionType: 'finalMission',
          sessionId: _sessionUuid,
          mode: activity.mode,
          evidenceSkill: evidenceSkill,
          canDoIds: activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
          wasFallback: submission.wasFallback,
        );
  }

  Future<void> _next() async {
    await _recording;
    if (!mounted) return;
    final activities = widget.mission.activities;
    if (_index < activities.length - 1) {
      setState(() => _index++);
      return;
    }

    final result = FinalMissionScoring.score(
      mission: widget.mission,
      scoresBySkill: _scoresBySkill,
    );
    await ref
        .read(assessmentAttemptRepositoryProvider)
        .completeFinalMissionAttempt(
          attemptId: _attemptId!,
          stagesCompletedJson: jsonEncode(
            widget.mission.stages.map((s) => s.id).toList(),
          ),
          outcome: result.passed ? 'passed' : 'notYetComplete',
        );
    // The Tests tab's final-mission card reads the latest attempt from a
    // cached provider — refresh it now that this attempt is persisted.
    ref.invalidate(latestFinalMissionAttemptProvider);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_result != null) {
      return _MissionResultView(
        result: _result!,
        passMark: widget.mission.minimumCriterionScore,
      );
    }

    final mission = widget.mission;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!_started) {
      return TestIntroView(
        overline: l10n.testsMissionOverline,
        title: mission.title,
        titleAr: mission.titleAr,
        lead: l10n.testsMissionBody(widget.levelCode),
        meta: mission.estimatedMinutes.length == 2
            ? l10n.testsMissionMeta(
                mission.activities.length,
                mission.stages.length,
                mission.estimatedMinutes[0],
                mission.estimatedMinutes[1],
              )
            : null,
        heading: l10n.testIntroStagesHeading,
        rows: [
          for (final (i, stage) in mission.stages.indexed)
            TestIntroRow(
              number: i + 1,
              title: stage.title,
              titleAr: stage.titleAr,
              trailing: l10n.testIntroTaskCount(stage.activityIds.length),
            ),
        ],
        startLabel: l10n.finalMissionStartButton,
        starting: _starting,
        onStart: _start,
      );
    }

    final activity = mission.activities[_index];
    final stage = mission.stages.firstWhere(
      (s) => s.activityIds.contains(activity.id),
      orElse: () => mission.stages.last,
    );
    return TestQuestionFrame(
      groupSizes: [for (final s in mission.stages) s.activityIds.length],
      completed: _index,
      eyebrow: TestEyebrow(
        skill: activity.skill,
        text: l10n.testQuestionEyebrow(
          isArabic ? stage.titleAr : stage.title,
          stage.activityIds.indexOf(activity.id) + 1,
          stage.activityIds.length,
        ),
      ),
      // The mission is a scenario worked through with feedback, not a
      // secure test — its answers stay marked.
      testMode: false,
      onContinue: _next,
      child: buildActivityView(
        key: ValueKey(activity.id),
        activity,
        learnerId: widget.learnerId,
        onSubmitted: (s) => _recording = _handleSubmitted(activity, s),
        mediaByKey: widget.mediaByKey,
      ),
    );
  }
}

/// Test-only construction path for [_MissionResultView], mirroring
/// `buildFinalAssessmentResultViewForTest`.
@visibleForTesting
Widget buildFinalMissionResultViewForTest(
  FinalMissionScoringResult result, {
  double passMark = 0.6,
}) => _MissionResultView(result: result, passMark: passMark);

/// The mission's result: passed or not yet, then each required skill group
/// with its score against the pass mark (or "Waiting for review").
class _MissionResultView extends StatelessWidget {
  const _MissionResultView({required this.result, required this.passMark});

  final FinalMissionScoringResult result;
  final double passMark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void done() => Navigator.of(context).pop();

    return TestResultView(
      overline: l10n.testsMissionOverline,
      title: result.passed
          ? l10n.missionResultPassedTitle
          : l10n.missionResultNotYetTitle,
      body: result.passed
          ? l10n.missionResultPassedBody
          : l10n.missionResultNotYetBody,
      primaryLabel: result.passed
          ? l10n.finalMissionDone
          : l10n.finalAssessmentWhatsNext,
      primaryArrow: !result.passed,
      onPrimary: result.passed
          ? done
          : () {
              done();
              context.go('/learn');
            },
      secondaryLabel: result.passed ? null : l10n.finalMissionDone,
      onSecondary: done,
      children: [
        SectionHeading(l10n.testsResultHowYouDid),
        ResultRowsCard(
          rows: [
            for (final group in result.groupResults)
              _groupRow(context, l10n, group),
          ],
        ),
      ],
    );
  }

  Widget _groupRow(
    BuildContext context,
    AppLocalizations l10n,
    SkillGroupResult group,
  ) {
    final skills = [for (final s in group.skills) Skill.parse(s)];
    final labels = <String>{for (final s in skills) learnerSkillLabel(l10n, s)};
    final pending = !group.passed && group.pendingReviewCount > 0;
    final scored = group.scoredEvidenceCount > 0 && !pending;
    return SkillResultRow(
      icon: skillIcon(skills.first),
      label: labels.join(' / '),
      trailing: group.passed
          ? StatusPill(
              label: l10n.finalAssessmentSkillPassed,
              tone: StatusTone.success,
              icon: Icons.check_rounded,
            )
          : pending
          ? StatusPill(label: l10n.testsWaitingReview)
          : StatusPill(
              label: l10n.finalAssessmentSkillNotMet,
              tone: StatusTone.attention,
              icon: Icons.refresh_rounded,
            ),
      progress: scored ? group.averageScore.clamp(0, 1) : null,
      progressDone: group.passed,
      caption: pending
          ? l10n.testsPendingBody
          : scored
          ? l10n.testsScorePassMark(
              (group.averageScore * 100).round(),
              (passMark * 100).round(),
            )
          : null,
    );
  }
}
