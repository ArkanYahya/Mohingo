import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/capstone.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../domain/final_assessment_scoring.dart';

/// Test-only construction path for [_AssessmentResultView] — the class
/// itself stays private since its only real entry point is
/// [_FinalAssessmentBodyState]; this just gives widget tests a way to pump
/// the result view directly without driving a full attempt through.
@visibleForTesting
Widget buildFinalAssessmentResultViewForTest({
  required List<FinalAssessmentSectionResult> results,
  required bool overallPassed,
}) {
  return _AssessmentResultView(results: results, overallPassed: overallPassed);
}

class _FlatItem {
  const _FlatItem(this.sectionKey, this.activity);
  final String sectionKey;
  final Activity activity;
}

List<_FlatItem> _flatten(FinalAssessment assessment) => [
  for (final entry in assessment.sections.entries)
    for (final activity in entry.value.activities)
      _FlatItem(entry.key, activity),
];

/// The A1 Final Assessment — the bundle's own secured, unseen `sections`
/// (`listening`/`reading`/`writing`/`speaking`/`mediation`), sequenced in
/// order. Scored strictly per section, never one blended average
/// (`decisionRule.noSingleOverallAverage`); a section with any
/// free-response item this app can't auto-grade is honestly reported as
/// pending review rather than guessed at.
class FinalAssessmentScreen extends ConsumerWidget {
  const FinalAssessmentScreen({super.key});

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
        data: (learner) => _FinalAssessmentBody(
          assessment: index.bundle.finalAssessment,
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

class _FinalAssessmentBody extends ConsumerStatefulWidget {
  const _FinalAssessmentBody({
    required this.assessment,
    required this.courseId,
    required this.mediaByKey,
    required this.learnerId,
  });

  final FinalAssessment assessment;
  final String courseId;
  final Map<String, MediaSpecification> mediaByKey;
  final int learnerId;

  @override
  ConsumerState<_FinalAssessmentBody> createState() =>
      _FinalAssessmentBodyState();
}

class _FinalAssessmentBodyState extends ConsumerState<_FinalAssessmentBody> {
  late final List<_FlatItem> _items = _flatten(widget.assessment);

  int? _attemptId;
  String? _sessionUuid;
  int _index = 0;
  ActivitySubmission? _lastSubmission;
  List<FinalAssessmentSectionResult>? _results;
  final Map<String, List<double?>> _scoresBySection = {};
  bool _started = false;
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    final repository = ref.read(assessmentAttemptRepositoryProvider);
    final attemptId = await repository.startFinalAssessmentAttempt(
      learnerId: widget.learnerId,
      courseId: widget.courseId,
    );
    final attemptRow = await repository.latestFinalAssessmentAttempt(
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
    _FlatItem item,
    ActivitySubmission submission,
  ) async {
    final evidenceSkill = resolveEvidenceSkill(item.activity, submission);
    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: item.activity.id,
          sessionType: 'finalAssessment',
          sessionId: _sessionUuid,
          mode: item.activity.mode,
          evidenceSkill: evidenceSkill,
          canDoIds: item.activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
          wasFallback: submission.wasFallback,
        );
    _scoresBySection
        .putIfAbsent(item.sectionKey, () => [])
        .add(submission.score);
    if (mounted) setState(() => _lastSubmission = submission);
  }

  Future<void> _next() async {
    if (_index < _items.length - 1) {
      setState(() {
        _index++;
        _lastSubmission = null;
      });
      return;
    }

    final results = FinalAssessmentScoring.score(
      assessment: widget.assessment,
      scoresBySection: _scoresBySection,
    );
    final overallPassed = FinalAssessmentScoring.overallPassed(
      widget.assessment,
      results,
    );
    await ref
        .read(assessmentAttemptRepositoryProvider)
        .completeFinalAssessmentAttempt(
          attemptId: _attemptId!,
          sectionResultsJson: jsonEncode([
            for (final r in results)
              {
                'section': r.section,
                'status': r.status.name,
                'averageScore': r.averageScore,
                'scoredCount': r.scoredCount,
                'pendingReviewCount': r.pendingReviewCount,
              },
          ]),
          outcomeSummaryJson: jsonEncode({
            'overallPassed': overallPassed,
            'requiredSkills': widget.assessment.requiredSkills,
          }),
        );
    // The Tests tab's final-assessment card reads the latest attempt from a
    // cached provider — refresh it now that this attempt is persisted.
    ref.invalidate(latestFinalAssessmentAttemptProvider);
    if (mounted) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_results != null) {
      return _AssessmentResultView(
        results: _results!,
        overallPassed: FinalAssessmentScoring.overallPassed(
          widget.assessment,
          _results!,
        ),
      );
    }

    if (!_started) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.assessment.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.finalAssessmentIntroBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _starting ? null : _start,
                  child: _starting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.finalAssessmentStartButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _items[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${sectionLabel(l10n, item.sectionKey)} — ${_index + 1}/${_items.length}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildActivityView(
                key: ValueKey(item.activity.id),
                item.activity,
                learnerId: widget.learnerId,
                onSubmitted: (s) => _handleSubmitted(item, s),
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

class _AssessmentResultView extends StatelessWidget {
  const _AssessmentResultView({
    required this.results,
    required this.overallPassed,
  });

  final List<FinalAssessmentSectionResult> results;
  final bool overallPassed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.finalAssessmentResultTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                overallPassed
                    ? l10n.finalAssessmentOverallPassed
                    : l10n.finalAssessmentOverallNotYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              for (final result in results)
                Card(
                  child: ListTile(
                    title: Text(sectionLabel(l10n, result.section)),
                    subtitle: result.scoredCount > 0
                        ? Text(
                            l10n.finalAssessmentSectionScore(
                              (result.averageScore * 100).round(),
                            ),
                          )
                        : null,
                    trailing: Text(switch (result.status) {
                      FinalAssessmentSectionStatus.passed =>
                        l10n.finalAssessmentSkillPassed,
                      FinalAssessmentSectionStatus.notMet =>
                        l10n.finalAssessmentSkillNotMet,
                      FinalAssessmentSectionStatus.pendingReview =>
                        l10n.finalAssessmentSkillPendingReview,
                    }),
                  ),
                ),
              const SizedBox(height: 16),
              // The spacer lives inside the conditional so the pass path —
              // where this button isn't rendered at all — doesn't leave a
              // stray gap above "Done".
              if (!overallPassed) ...[
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/learn');
                  },
                  child: Text(l10n.finalAssessmentWhatsNext),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.finalAssessmentDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
