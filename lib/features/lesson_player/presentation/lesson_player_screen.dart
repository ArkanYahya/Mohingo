import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/models/registry_items.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/local/database.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evaluation/evaluation_context.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_chrome.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../activity_engine/providers/online_refinement_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/domain/repositories/daily_task_event_repository.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../review/providers/review_providers.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../domain/lesson_phases.dart';
import 'lesson_review_screen.dart' show lessonReviewAttemptsProvider;
import 'widgets/activity_eyebrow.dart';
import 'widgets/lesson_complete_view.dart';
import 'widgets/lesson_conversation_step.dart';
import 'widgets/lesson_key_phrases_step.dart';
import 'widgets/lesson_progress_bar.dart';
import 'widgets/lesson_top_bar.dart';

/// Sequences through one lesson's activities, rendering each via the
/// activity-engine registry, recording every submission, and refreshing
/// unit mastery once the lesson is complete.
///
/// A lesson with an encounter conversation opens on two intro screens —
/// [LessonConversationStep], then [LessonKeyPhrasesStep] when the lesson
/// lists phrases or grammar — before its first activity. They're steps in
/// the progress bar (its first group), shown when the lesson starts from
/// the beginning and skipped on a mid-lesson resume.
///
/// Each activity is hosted in an [ActivityFrameScope]: a slim top bar
/// (close + [LessonProgressBar]), the phase · skill line, the question,
/// and Check pinned to the bottom, which becomes the feedback panel whose
/// Continue moves on. See docs/DESIGN_SYSTEM.md.
///
/// Resume behaviour: if [LessonProgressData.lastActivityId] exists and
/// isn't the lesson's final activity, playback resumes right after it
/// (interrupted mid-lesson), after rehydrating the skipped activities'
/// recorded answers so a later `letterSequence` rubric that references one
/// of them still grades. Otherwise — no prior progress, or the lesson was
/// previously finished — playback starts at activity 0; revisiting a
/// finished lesson is a full replay, which appends fresh evidence rather
/// than overwriting history (`ActivityAttemptRepository.recordAttempt` is
/// insert-only). See docs/DATA_MODEL.md.
class LessonPlayerScreen extends ConsumerWidget {
  const LessonPlayerScreen({
    required this.unitId,
    required this.lessonId,
    super.key,
  });

  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) {
        final lesson = index.lessonsById[lessonId];
        final unit = index.unitsById[unitId];
        if (lesson == null || unit == null) {
          return const _ErrorScaffold(message: 'Lesson not found');
        }
        return learnerAsync.when(
          loading: () => const _LoadingScaffold(),
          error: (error, _) => _ErrorScaffold(message: '$error'),
          data: (learner) => _LessonPlayerBody(
            unitId: unitId,
            unit: unit,
            lesson: lesson,
            learnerId: learner.id,
            learnerName: learner.name,
            masteryPolicy: index.bundle.domain.masteryPolicy,
            mediaByKey: index.bundle.mediaSpecifications,
            unitNumber:
                index.bundle.units.indexWhere((u) => u.id == unitId) + 1,
            phrases: [for (final id in lesson.chunks) ?index.chunkById[id]],
            grammar: [for (final id in lesson.grammar) ?index.grammarById[id]],
          ),
        );
      },
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

class _LessonPlayerBody extends ConsumerStatefulWidget {
  const _LessonPlayerBody({
    required this.unitId,
    required this.unit,
    required this.lesson,
    required this.learnerId,
    required this.learnerName,
    required this.masteryPolicy,
    required this.mediaByKey,
    required this.unitNumber,
    required this.phrases,
    required this.grammar,
  });

  final String unitId;
  final Unit unit;
  final Lesson lesson;
  final int learnerId;
  final String? learnerName;
  final MasteryPolicy masteryPolicy;
  final Map<String, MediaSpecification> mediaByKey;

  /// 1-based position of the unit in its level, as Home numbers it.
  final int unitNumber;

  /// The lesson's chunk-registry phrases and grammar, in lesson order.
  final List<ChunkItem> phrases;
  final List<GrammarItem> grammar;

  @override
  ConsumerState<_LessonPlayerBody> createState() => _LessonPlayerBodyState();
}

class _LessonPlayerBodyState extends ConsumerState<_LessonPlayerBody> {
  int? _currentIndex;
  ActivitySubmission? _lastSubmission;
  bool _finished = false;

  /// The current activity's submission being recorded — Continue waits
  /// for it, so finishing the lesson never refreshes mastery before the
  /// last attempt is saved.
  Future<void>? _recording;

  /// Set while [_next] runs, so a double tap on Continue can't skip an
  /// activity.
  bool _advancing = false;

  /// The intro screen showing (0 = conversation, 1 = key phrases), or
  /// null once the activities have started.
  int? _introIndex;

  /// How many intro screens this lesson has: none without an encounter
  /// conversation; key phrases only when there are phrases or grammar.
  late final int _introCount = widget.lesson.encounterDialogue.isEmpty
      ? 0
      : (widget.phrases.isEmpty && widget.grammar.isEmpty ? 1 : 2);
  final List<ActivityCorrectness> _results = [];

  /// The skill of each activity answered this session, in order — the
  /// lesson-complete screen's "Skills practised".
  final List<Skill> _skills = [];
  final Map<String, String> _previousAnswers = {};

  @override
  void initState() {
    super.initState();
    _resolveStartIndex();
  }

  Future<void> _resolveStartIndex() async {
    final repository = ref.read(unitLessonProgressRepositoryProvider);
    final existing = await repository.lessonProgress(
      learnerId: widget.learnerId,
      lessonId: widget.lesson.id,
    );
    final activities = widget.lesson.activities;
    var startIndex = 0;
    final lastActivityId = existing?.lastActivityId;
    if (lastActivityId != null && activities.isNotEmpty) {
      final lastIndex = activities.indexWhere((a) => a.id == lastActivityId);
      if (lastIndex != -1 && lastIndex < activities.length - 1) {
        startIndex = lastIndex + 1;
      }
      // else: lastActivityId was the final activity (lesson previously
      // completed) -> intentional replay from the start.
    }
    if (startIndex > 0) {
      await _rehydratePreviousAnswers(skippedCount: startIndex);
    }
    if (mounted) {
      setState(() {
        _currentIndex = startIndex;
        _introIndex = startIndex == 0 && _introCount > 0 ? 0 : null;
      });
    }
  }

  /// Refills [_previousAnswers] from already-recorded attempts before
  /// resuming a lesson part-way through.
  ///
  /// [_previousAnswers] is in-memory and per-`State`, so on a mid-lesson
  /// resume it starts empty — but a later activity's `letterSequence`
  /// rubric can reference an earlier activity's answer
  /// (`"reference": "previousAnswer:<id>"`), and that earlier activity is
  /// exactly the kind that was answered in the *previous* session and is
  /// now being skipped. Without this the reference resolves to nothing and
  /// the activity silently drops to `notAutoGraded`, costing the learner
  /// mastery evidence purely because they backed out and came back.
  ///
  /// Only the [skippedCount] activities being skipped are rehydrated — a
  /// reference always points backwards, and reading no further keeps a
  /// stale answer from an older replay of a *later* activity out of the
  /// map. Answers are stored exactly as [_handleSubmitted] writes them:
  /// JSON-encoded, and only kept when they decode to a plain string.
  ///
  /// The same latest attempts also seed [_results] and [_skills], so the
  /// lesson-complete screen sums up the whole lesson rather than only the
  /// activities answered in this sitting. (An answer still queued for
  /// online checking has no attempt row yet, and is left out.)
  Future<void> _rehydratePreviousAnswers({required int skippedCount}) async {
    final answered = widget.lesson.activities
        .take(skippedCount)
        .map((a) => a.id)
        .toSet();
    if (answered.isEmpty) return;

    final attempts = await ref
        .read(activityAttemptRepositoryProvider)
        .attemptsForLessons(
          learnerId: widget.learnerId,
          lessonIds: [widget.lesson.id],
        );

    final latestByActivity = <String, ActivityAttempt>{};
    for (final attempt in attempts) {
      if (attempt.sessionType != 'lesson') continue;
      if (!answered.contains(attempt.activityId)) continue;
      final existing = latestByActivity[attempt.activityId];
      if (existing == null ||
          !attempt.attemptedAt.isBefore(existing.attemptedAt)) {
        latestByActivity[attempt.activityId] = attempt;
      }
    }

    for (final entry in latestByActivity.entries) {
      final rawAnswer = entry.value.rawAnswer;
      if (rawAnswer == null) continue;
      final decoded = _decodeRawAnswer(rawAnswer);
      if (decoded != null) _previousAnswers[entry.key] = decoded;
    }

    for (final activity in widget.lesson.activities.take(skippedCount)) {
      final attempt = latestByActivity[activity.id];
      if (attempt == null) continue;
      _results.add(switch (attempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      });
      _skills.add(activity.skill);
    }
  }

  /// A stored `rawAnswer` decoded back to the plain string
  /// [_previousAnswers] holds, or `null` if it isn't one (a structured
  /// answer, or unparseable JSON written by an older build).
  String? _decodeRawAnswer(String rawAnswer) {
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _handleSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    final rawAnswerJson = submission.rawAnswerJson;
    if (rawAnswerJson != null) {
      final decoded = _decodeRawAnswer(rawAnswerJson);
      if (decoded != null) _previousAnswers[activity.id] = decoded;
    }

    final evidenceSkill = resolveEvidenceSkill(activity, submission);

    if (submission.pendingOnlineRefinement) {
      await ref
          .read(pendingRefinementRepositoryProvider)
          .enqueue(
            learnerId: widget.learnerId,
            activityId: activity.id,
            lessonId: widget.lesson.id,
            unitId: widget.unitId,
            canDoIds: activity.canDo,
            rawAnswer: submission.rawAnswerJson!,
            evidenceSkill: evidenceSkill.name,
            mode: activity.mode.name,
            localScore: submission.score ?? 0.0,
            wasFallback: submission.wasFallback,
          );
      // Without this, a learner who is online the *entire* time they use
      // the app would never see this resolve: the drainer otherwise only
      // triggers at app start (before this item existed) and on a
      // connectivity *transition* (which never fires if the device was
      // never offline to begin with) — see
      // online_refinement_providers.dart's doc comment.
      ref.read(pendingRefinementDrainerProvider).triggerDrain();
    } else {
      await ref
          .read(activityAttemptRepositoryProvider)
          .recordAttempt(
            learnerId: widget.learnerId,
            activityId: activity.id,
            lessonId: widget.lesson.id,
            sessionType: 'lesson',
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

    await ref
        .read(unitLessonProgressRepositoryProvider)
        .recordLessonPosition(
          learnerId: widget.learnerId,
          lessonId: widget.lesson.id,
          unitId: widget.unitId,
          lastActivityId: activity.id,
        );

    _results.add(submission.correctness);
    _skills.add(activity.skill);
    // Invalidated here too, not just in _next()'s finish branch: a learner
    // who answers some activities and backs out without finishing the
    // lesson still moves it from "not started" to "in progress" in the
    // database, and the unit overview (a ref.watch consumer) should reflect
    // that even though the lesson was never completed.
    ref.invalidate(
      lessonProgressForUnitProvider((
        learnerId: widget.learnerId,
        unitId: widget.unitId,
      )),
    );
    ref.invalidate(
      lessonAttemptsForUnitProvider((
        learnerId: widget.learnerId,
        unitId: widget.unitId,
      )),
    );
    // Also invalidated on every submission (not just at lesson finish): the
    // Learn spine's/Home's "current unit" position is meant to follow
    // wherever the learner is actually active right now, not just where
    // they last fully finished a lesson.
    ref.invalidate(allLessonProgressProvider);
    // A "Practice again" replay recorded a fresh attempt for this lesson —
    // without this, LessonReviewScreen would keep showing the pre-replay
    // data for the rest of the app session (it has no other trigger to
    // refetch). See docs/superpowers/specs/
    // 2026-09-09-lesson-answer-review-design.md.
    ref.invalidate(
      lessonReviewAttemptsProvider((
        learnerId: widget.learnerId,
        lessonId: widget.lesson.id,
      )),
    );
  }

  void _onSubmitted(Activity activity, ActivitySubmission submission) {
    setState(() => _lastSubmission = submission);
    _recording = _handleSubmitted(activity, submission);
  }

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    try {
      await _recording;
      await _advance();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _advance() async {
    final activities = widget.lesson.activities;
    final isLastActivity = _currentIndex! >= activities.length - 1;

    if (!isLastActivity) {
      if (!mounted) return;
      setState(() {
        _currentIndex = _currentIndex! + 1;
        _lastSubmission = null;
        _recording = null;
      });
      return;
    }

    await ref
        .read(masteryAggregationServiceProvider)
        .refreshUnitProgress(
          learnerId: widget.learnerId,
          unit: widget.unit,
          masteryPolicy: widget.masteryPolicy,
        );
    // Invalidation is owned here, at the one place lesson progress actually
    // changes, rather than by the screens that read it: this lesson player
    // can exit by `pop` ("Back to unit") *or* `pushReplacement` ("Next
    // lesson"), and go_router's `pushReplacement` never completes the
    // replaced route's future — so an invalidate-after-`await context.push`
    // on the unit overview would stop firing forever after the first "Next
    // lesson" tap. Every consumer `ref.watch`es these, so they rebuild with
    // fresh data whichever way the learner leaves.
    ref.invalidate(allUnitProgressProvider);
    ref.invalidate(
      lessonProgressForUnitProvider((
        learnerId: widget.learnerId,
        unitId: widget.unitId,
      )),
    );
    ref.invalidate(currentStreakDaysProvider);

    // Feeds Home's "Finish a lesson" daily task — the one place a lesson
    // actually finishing is known.
    await ref
        .read(dailyTaskEventRepositoryProvider)
        .recordEvent(
          learnerId: widget.learnerId,
          taskType: DailyTaskType.lesson,
        );
    ref.invalidate(dailyTaskCountsProvider);

    // What this lesson taught comes back in the Review tab from tomorrow.
    await ref
        .read(vocabularyReviewServiceProvider)
        .enrollLesson(learnerId: widget.learnerId, lesson: widget.lesson);
    ref.invalidate(allVocabularyReviewStateProvider);
    ref.invalidate(dueVocabularyProvider);

    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == null) {
      return const _LoadingScaffold();
    }
    if (_finished) {
      final lessons = widget.unit.lessons;
      final position = lessons.indexWhere((l) => l.id == widget.lesson.id);
      final nextLesson = position >= 0 && position < lessons.length - 1
          ? lessons[position + 1]
          : null;
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: LessonCompleteView(
            lesson: widget.lesson,
            results: _results,
            skills: _skills,
            phraseCount: widget.phrases.length,
            streakDays: ref.watch(currentStreakDaysProvider).value,
            nextLesson: nextLesson,
            nextLessonNumber: position + 2,
            progress: LessonProgressBar(
              groupSizes: _groupSizes,
              completed: _introCount + widget.lesson.activities.length,
            ),
            onNext: nextLesson != null
                ? () => context.pushReplacement(
                    '/lesson-player/${widget.unitId}/${nextLesson.id}',
                  )
                : () => context.pop(),
            onReviewAnswers: () => context.pushReplacement(
              '/lesson-review/${widget.unitId}/${widget.lesson.id}',
            ),
            onClose: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final activities = widget.lesson.activities;
    final introIndex = _introIndex;
    final progress = LessonProgressBar(
      groupSizes: _groupSizes,
      completed:
          introIndex ??
          _introCount + _currentIndex! + (_lastSubmission == null ? 0 : 1),
    );

    return Scaffold(
      body: SafeArea(
        // The bottom bar pads itself for the system inset, so its colour
        // runs to the bottom edge of the screen.
        bottom: false,
        child: Column(
          children: [
            LessonTopBar(
              onClose: () => Navigator.of(context).maybePop(),
              progress: progress,
            ),
            Expanded(
              child: introIndex != null
                  ? _buildIntro(context, introIndex)
                  : _buildActivity(activities[_currentIndex!]),
            ),
          ],
        ),
      ),
    );
  }

  /// The progress bar's groups: the intro (when there is one), then one
  /// per run of same-mode activities.
  List<int> get _groupSizes => [
    if (_introCount > 0) _introCount,
    ...phaseGroupSizes([for (final a in widget.lesson.activities) a.mode]),
  ];

  Widget _buildIntro(BuildContext context, int introIndex) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = widget.lesson;
    final overline = l10n.homeUnitLessonOverline(
      widget.unitNumber,
      widget.unit.lessons.indexWhere((l) => l.id == lesson.id) + 1,
    );
    final isLast = introIndex == _introCount - 1;
    final continueLabel = isLast
        ? l10n.lessonIntroStartPractice
        : l10n.activityContinue;
    void onContinue() => setState(() {
      _introIndex = isLast ? null : introIndex + 1;
    });

    return introIndex == 0
        ? LessonConversationStep(
            key: const ValueKey('intro-conversation'),
            overline: overline,
            title: lesson.title,
            titleAr: lesson.titleAr,
            lines: lesson.encounterDialogue,
            sceneAr:
                (lesson.raw['encounter'] as Map<String, dynamic>?)?['sceneAr']
                    as String?,
            continueLabel: continueLabel,
            onContinue: onContinue,
          )
        : LessonKeyPhrasesStep(
            key: const ValueKey('intro-key-phrases'),
            overline: overline,
            lessonId: lesson.id,
            phrases: widget.phrases,
            grammar: widget.grammar,
            continueLabel: continueLabel,
            onContinue: onContinue,
          );
  }

  Widget _buildActivity(Activity activity) {
    return ActivityFrameScope(
      onContinue: _next,
      header: ActivityEyebrow(mode: activity.mode, skill: activity.skill),
      usefulPhrases: [
        for (final phrase in widget.phrases)
          if (phrase.productive) phrase.text,
      ],
      child: buildActivityView(
        key: ValueKey(activity.id),
        activity,
        learnerId: widget.learnerId,
        onSubmitted: (submission) => _onSubmitted(activity, submission),
        mediaByKey: widget.mediaByKey,
        evaluationContext: EvaluationContext(
          profileName: widget.learnerName,
          previousAnswers: Map.unmodifiable(_previousAnswers),
        ),
      ),
    );
  }
}
