import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/capstone.dart';
import '../../../content/models/media_specification.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/status_pill.dart';
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
import '../domain/final_assessment_scoring.dart';

/// Test-only construction path for [_AssessmentResultView] — the class
/// itself stays private since its only real entry point is
/// [_FinalAssessmentBodyState]; this just gives widget tests a way to pump
/// the result view directly without driving a full attempt through.
@visibleForTesting
Widget buildFinalAssessmentResultViewForTest({
  required List<FinalAssessmentSectionResult> results,
  required bool overallPassed,
  required String levelCode,
  Map<String, double> passMarks = const {},
}) {
  return _AssessmentResultView(
    results: results,
    overallPassed: overallPassed,
    levelCode: levelCode,
    passMarks: passMarks,
  );
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

/// The current level's Final Assessment — the bundle's own secured, unseen
/// `sections` (`listening`/`reading`/`writing`/`speaking`/`mediation`),
/// sequenced in order. Scored strictly per section, never one blended
/// average (`decisionRule.noSingleOverallAverage`); a section with any
/// free-response item this app can't auto-grade is honestly reported as
/// pending review rather than guessed at.
///
/// Which level's assessment this is follows [currentCourseProvider], so an
/// A2 learner gets A2's — the Tests tab that opens it follows the same seam.
class FinalAssessmentScreen extends ConsumerWidget {
  const FinalAssessmentScreen({super.key});

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
        data: (learner) => _FinalAssessmentBody(
          assessment: course.index.bundle.finalAssessment,
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

class _FinalAssessmentBody extends ConsumerStatefulWidget {
  const _FinalAssessmentBody({
    required this.assessment,
    required this.courseId,
    required this.levelCode,
    required this.mediaByKey,
    required this.learnerId,
  });

  final FinalAssessment assessment;
  final String courseId;

  /// The CEFR code of the level [assessment] closes, for the copy naming it.
  final String levelCode;

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

  /// The current answer's save, awaited before moving on — the "Answer
  /// saved" panel (and Next question) appears as soon as Check is tapped.
  Future<void>? _recording;
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
    _FlatItem item,
    ActivitySubmission submission,
  ) async {
    final evidenceSkill = resolveEvidenceSkill(item.activity, submission);
    // Counted before the save so the section's result can't miss it.
    _scoresBySection
        .putIfAbsent(item.sectionKey, () => [])
        .add(submission.score);
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
  }

  Future<void> _next() async {
    await _recording;
    if (!mounted) return;
    if (_index < _items.length - 1) {
      setState(() => _index++);
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
        passMarks: {
          for (final key in widget.assessment.sections.keys)
            key: widget.assessment.minimumScoreForSection(key),
        },
        levelCode: widget.levelCode,
        results: _results!,
        overallPassed: FinalAssessmentScoring.overallPassed(
          widget.assessment,
          _results!,
        ),
      );
    }

    final assessment = widget.assessment;
    final sections = assessment.sections.entries.toList();
    if (!_started) {
      return TestIntroView(
        overline: l10n.testsAssessmentOverline,
        title: assessment.title,
        titleAr: assessment.titleAr,
        lead: l10n.finalAssessmentIntroBody(widget.levelCode),
        meta: assessment.estimatedMinutes.length == 2
            ? l10n.testsAssessmentMeta(
                _items.length,
                sections.length,
                assessment.estimatedMinutes[0],
                assessment.estimatedMinutes[1],
              )
            : null,
        heading: l10n.testIntroCoversHeading,
        rows: [
          for (final MapEntry(:key, :value) in sections)
            TestIntroRow(
              icon: _sectionIcon(key),
              title: sectionLabel(l10n, key),
              trailing: l10n.testIntroQuestionCount(value.activities.length),
            ),
        ],
        note: l10n.testRulesNote,
        startLabel: l10n.finalAssessmentStartButton,
        starting: _starting,
        onStart: _start,
      );
    }

    final item = _items[_index];
    final sectionItems = [
      for (final i in _items)
        if (i.sectionKey == item.sectionKey) i,
    ];
    return TestQuestionFrame(
      groupSizes: [for (final e in sections) e.value.activities.length],
      completed: _index,
      eyebrow: TestEyebrow(
        skill: item.activity.skill,
        text: l10n.testQuestionEyebrow(
          sectionLabel(l10n, item.sectionKey),
          sectionItems.indexOf(item) + 1,
          sectionItems.length,
        ),
      ),
      // A secure exit test: answers are saved, not marked, and listening
      // has no transcript.
      testMode: true,
      onContinue: _next,
      child: buildActivityView(
        key: ValueKey(item.activity.id),
        item.activity,
        learnerId: widget.learnerId,
        onSubmitted: (s) => _recording = _handleSubmitted(item, s),
        mediaByKey: widget.mediaByKey,
      ),
    );
  }
}

/// The icon for an assessment section key.
IconData _sectionIcon(String sectionKey) => switch (sectionKey) {
  'listening' => Icons.headphones_rounded,
  'reading' => Icons.menu_book_rounded,
  'writing' => Icons.edit_note_rounded,
  'speaking' => Icons.record_voice_over_rounded,
  _ => Icons.translate_rounded,
};

/// The assessment's result: passed or not yet with how many skills passed,
/// then each section with its score against its own pass mark, or
/// "Waiting for review" when its answers can't be scored yet.
class _AssessmentResultView extends StatelessWidget {
  const _AssessmentResultView({
    required this.results,
    required this.overallPassed,
    required this.levelCode,
    required this.passMarks,
  });

  final List<FinalAssessmentSectionResult> results;
  final bool overallPassed;

  /// The CEFR code of the level just sat, for "You passed A2".
  final String levelCode;

  /// Each section's pass mark (0–1), by section key.
  final Map<String, double> passMarks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final passed = results
        .where((r) => r.status == FinalAssessmentSectionStatus.passed)
        .length;
    void done() => Navigator.of(context).pop();

    return TestResultView(
      overline: l10n.testsAssessmentOverline,
      title: overallPassed
          ? l10n.assessmentResultPassedTitle(levelCode)
          : l10n.assessmentResultNotYetTitle,
      body: l10n.assessmentResultBody(passed, results.length),
      primaryLabel: overallPassed
          ? l10n.finalAssessmentDone
          : l10n.finalAssessmentWhatsNext,
      primaryArrow: !overallPassed,
      onPrimary: overallPassed
          ? done
          : () {
              done();
              context.go('/learn');
            },
      secondaryLabel: overallPassed ? null : l10n.finalAssessmentDone,
      onSecondary: done,
      children: [
        SectionHeading(l10n.testsResultHowYouDid),
        ResultRowsCard(
          rows: [for (final result in results) _sectionRow(l10n, result)],
        ),
      ],
    );
  }

  Widget _sectionRow(AppLocalizations l10n, FinalAssessmentSectionResult r) {
    final pending = r.status == FinalAssessmentSectionStatus.pendingReview;
    final scored = r.scoredCount > 0 && !pending;
    final mark = passMarks[r.section] ?? 0.6;
    return SkillResultRow(
      icon: _sectionIcon(r.section),
      label: sectionLabel(l10n, r.section),
      trailing: switch (r.status) {
        FinalAssessmentSectionStatus.passed => StatusPill(
          label: l10n.finalAssessmentSkillPassed,
          tone: StatusTone.success,
          icon: Icons.check_rounded,
        ),
        FinalAssessmentSectionStatus.notMet => StatusPill(
          label: l10n.finalAssessmentSkillNotMet,
          tone: StatusTone.attention,
          icon: Icons.refresh_rounded,
        ),
        FinalAssessmentSectionStatus.pendingReview => StatusPill(
          label: l10n.testsWaitingReview,
        ),
      },
      progress: scored ? r.averageScore.clamp(0, 1) : null,
      progressDone: r.status == FinalAssessmentSectionStatus.passed,
      caption: pending
          ? l10n.testsPendingBody
          : scored
          ? l10n.testsScorePassMark(
              (r.averageScore * 100).round(),
              (mark * 100).round(),
            )
          : null,
    );
  }
}
