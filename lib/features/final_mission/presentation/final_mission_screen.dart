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
  ActivitySubmission? _lastSubmission;
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
    _scoresBySkill
        .putIfAbsent(evidenceSkill.name, () => [])
        .add(submission.score);
    if (mounted) setState(() => _lastSubmission = submission);
  }

  Future<void> _next() async {
    final activities = widget.mission.activities;
    if (_index < activities.length - 1) {
      setState(() {
        _index++;
        _lastSubmission = null;
      });
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
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_result != null) {
      return _MissionResultView(result: _result!);
    }

    if (!_started) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mission.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.mission.scenario, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _starting ? null : _start,
                  child: _starting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.finalMissionStartButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activities = widget.mission.activities;
    final activity = activities[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mission.title} — ${_index + 1}/${activities.length}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildActivityView(
                key: ValueKey(activity.id),
                activity,
                onSubmitted: (s) => _handleSubmitted(activity, s),
                mediaByKey: widget.mediaByKey,
              ),
              if (_lastSubmission != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(l10n.lessonPlayerNext),
                  ),
                ),
            ],
          ),
        ),
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
