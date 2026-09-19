import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/capstone.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_intro_view.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../domain/final_mission_scoring.dart';

/// The A1 Final Mission — a scenario-based capstone reusing the bundle's own
/// `finalMission.activities` directly (no sampling needed, unlike the
/// placement test: this content is dedicated and pre-built). Scored per
/// [FinalMission.requiredSkillGroups] independently
/// (`noSingleAverageCompensation`), never one blended average.
class FinalMissionScreen extends ConsumerWidget {
  const FinalMissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);
    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) => learnerAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (error, _) => _ErrorScaffold(message: '$error'),
        data: (learner) => _FinalMissionBody(
          mission: index.bundle.finalMission,
          courseId: index.bundle.course.id,
          mediaByKey: index.bundle.mediaSpecifications,
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
    required this.mediaByKey,
    required this.learnerId,
  });

  final FinalMission mission;
  final String courseId;
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
      return _MissionResultView(result: _result!);
    }

    final mission = widget.mission;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!_started) {
      return TestIntroView(
        overline: l10n.testsMissionOverline,
        title: mission.title,
        titleAr: mission.titleAr,
        lead: l10n.testsMissionBody,
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

class _MissionResultView extends StatelessWidget {
  const _MissionResultView({required this.result});

  final FinalMissionScoringResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.finalMissionResultTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                result.passed ? Icons.celebration : Icons.hourglass_bottom,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                result.passed
                    ? l10n.finalMissionPassed
                    : l10n.finalMissionNotYetTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              for (final group in result.groupResults)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group.skills
                                .map((s) => skillLabel(l10n, Skill.parse(s)))
                                .join(' / '),
                          ),
                        ),
                        Icon(
                          group.passed
                              ? Icons.check_circle
                              : (group.pendingReviewCount > 0
                                    ? Icons.hourglass_bottom
                                    : Icons.error_outline),
                          color: group.passed
                              ? Colors.green
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.finalMissionDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
