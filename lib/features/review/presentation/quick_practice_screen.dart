import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lesson_reference_list.dart';
import '../../../core/widgets/section_heading.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/presentation/widgets/test_result_view.dart';
import '../domain/practice_set.dart';

/// A short practice run over a [PracticeSet] — a weak spot's lesson or a
/// grammar form — launched from the Review tab's "Practise weak spots" and a
/// grammar page's Quick practice.
///
/// Each question sits in the lesson player's frame with its normal
/// right/wrong feedback; a summary ends the set with the score, a note that
/// practice doesn't count towards mastery, a link to the lesson, Done and
/// Practise again.
///
/// Recorded with `sessionType: 'practiceReview'` — deliberately **not**
/// `'lesson'`, so it can never be picked up by
/// `ActivityAttemptRepository.masteryEvidenceForObjective` (which filters
/// to `sessionType='lesson'`) and can never contribute to Can-Do mastery,
/// matching "quick practice... without falsely marking the related Can-Do
/// mastered." See docs/DATA_MODEL.md.
class QuickPracticeScreen extends ConsumerStatefulWidget {
  const QuickPracticeScreen({required this.set, super.key});

  final PracticeSet set;

  @override
  ConsumerState<QuickPracticeScreen> createState() =>
      _QuickPracticeScreenState();
}

class _QuickPracticeScreenState extends ConsumerState<QuickPracticeScreen> {
  int _index = 0;

  /// Bumped by Practise again, so every activity view starts fresh.
  int _round = 0;
  final List<bool> _right = [];

  /// The current answer's save, awaited before moving on — the feedback
  /// panel (and its Continue) appears as soon as Check is tapped.
  Future<void>? _recording;

  List<Activity> get _activities => widget.set.activities;

  Future<void> _record(Activity activity, ActivitySubmission submission) async {
    _right.add(submission.correctness == ActivityCorrectness.correct);
    final learner = await ref.read(currentLearnerProvider.future);
    final evidenceSkill =
        submission.wasFallback &&
            activity is SpeakActivity &&
            activity.fallbackSkill != null
        ? Skill.parse(activity.fallbackSkill!)
        : activity.skill;
    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: learner.id,
          activityId: activity.id,
          sessionType: 'practiceReview',
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
    if (mounted) setState(() => _index++);
  }

  void _again() => setState(() {
    _index = 0;
    _round++;
    _right.clear();
    _recording = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final learnerAsync = ref.watch(currentLearnerProvider);
    final learner = learnerAsync.value;
    if (learner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_activities.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.grammarNoLinkedPractice)),
      );
    }
    if (_index >= _activities.length) return _summary(context);

    final activity = _activities[_index];
    return TestQuestionFrame(
      groupSizes: [_activities.length],
      completed: _index,
      eyebrow: TestEyebrow(
        skill: activity.skill,
        text: l10n.practiceEyebrow(
          '\u2068${widget.set.title}\u2069',
          _index + 1,
          _activities.length,
        ),
      ),
      testMode: false,
      onContinue: _next,
      child: buildActivityView(
        key: ValueKey('$_round-$_index-${activity.id}'),
        activity,
        learnerId: learner.id,
        onSubmitted: (s) => _recording = _record(activity, s),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(courseContentProvider('a1')).value;
    final lesson = widget.set.lesson;
    final right = _right.where((r) => r).length;
    return TestResultView(
      overline: l10n.practiceOverline('\u2068${widget.set.title}\u2069'),
      title: l10n.lessonReviewScore(right, _activities.length),
      body: l10n.practiceNoMastery,
      primaryLabel: l10n.quickPracticeDone,
      primaryArrow: false,
      onPrimary: () => context.pop(),
      secondaryLabel: l10n.practiceAgain,
      onSecondary: _again,
      children: [
        if (lesson != null && index != null) ...[
          const SizedBox(height: AppSpace.sm),
          SectionHeading(l10n.grammarPractisedInOverline),
          LessonReferenceList(
            index: index,
            lessons: [lesson],
            onTap: (l) => context.push(
              '/lesson-player/${index.unitIdByLessonId[l.id]}/${l.id}',
            ),
          ),
        ],
      ],
    );
  }
}
