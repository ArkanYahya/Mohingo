import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/evaluation_spec.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
import '../../domain/evaluation/grading_signals.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/online_refinement_providers.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';
import '../meaning_explanation.dart';
import '../widgets/activity_text_field.dart';

/// Renders a `write` activity: a free-text response, with a live word count
/// against [WriteActivity.wordGuide] when one is declared.
///
/// When [WriteActivity.accepted] lists specific acceptable answers (short,
/// closed-form writing tasks), the response is checked against them via
/// [answersMatch] — case-insensitively, tolerant of harmless punctuation
/// and apostrophe-style differences. Otherwise, when [WriteActivity.evaluation]
/// declares a structured [EvaluationSpec], the response is graded via
/// [evaluate]. Failing both, the submission is recorded as
/// [ActivityCorrectness.notAutoGraded] — some open-ended writing tasks have
/// no automatic right/wrong check at all. See docs/DATA_MODEL.md.
///
/// [learnerId] is only used to watch [latestAttemptProvider] once an
/// `onlineRefinement` submission goes pending — see [_resolvedSubmission].
class WriteActivityView extends ConsumerStatefulWidget {
  const WriteActivityView({
    required this.activity,
    required this.learnerId,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    this.reviewAttempt,
    super.key,
  });

  final WriteActivity activity;
  final int learnerId;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, pre-filled from this recorded attempt — never live-interactive,
  /// and [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed (and never sent through the online-refinement queue). See
  /// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  ConsumerState<WriteActivityView> createState() => _WriteActivityViewState();
}

class _WriteActivityViewState extends ConsumerState<WriteActivityView> {
  final _controller = TextEditingController();
  ActivitySubmission? _submission;

  /// True while the meaning signal is being computed for a submitted
  /// answer — Check is disabled, and a second tap is ignored.
  var _grading = false;

  /// Captured the instant [_submission] goes pending — a resolved attempt
  /// with an older `attemptedAt` belongs to an earlier retry of this same
  /// activity, not this submission, and must not be shown as its result.
  ///
  /// Truncated to whole seconds: `ActivityAttempts.attemptedAt` is stored
  /// at whole-second precision (Drift's `dateTime()` column default), so a
  /// millisecond-precision `DateTime.now()` captured here can otherwise
  /// compare as *after* the very row this submission itself produces a
  /// moment later, in the same wall-clock second — wrongly discarding a
  /// genuinely new result as a stale retry.
  DateTime? _pendingSince;

  DateTime _truncatedToSeconds(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeText(reviewAttempt.rawAnswer);
    if (decoded != null) _controller.text = decoded;
    final explanation = explanationIn(reviewAttempt.criteriaScores);
    _submission = ActivitySubmission(
      correctness: switch (reviewAttempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      },
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
      explanationEn: explanation?.en,
      explanationAr: explanation?.ar,
    );
  }

  String? _decodeText(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Grades the text. The task's rubric grades when it has one; its
  /// `accepted` list grades only a task without a rubric, and is otherwise
  /// the model answer shown after a miss. Written answers are graded as
  /// written — spelling is the learner's own (ADR 0009).
  ///
  /// A `keywordChecklist` task with model answers also gets the on-device
  /// meaning signal (ADR 0013), which may raise the rubric's score within
  /// `combineSignals`'s bound — unless the host grades on the rubric alone
  /// ([gradingSignalsEnabled]). The answer is queued for deferred grading
  /// when its rubric is marked `onlineRefinement`, or when a local grammar model is
  /// installed to judge it on the device.
  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submission != null || _grading) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
    if (evaluation is KeywordChecklistEvaluationSpec) {
      final rubric = evaluate(evaluation, text);
      final signalsOn = gradingSignalsEnabled(context);
      setState(() => _grading = true);
      // Read by parts where the groups carry meanings (ADR 0014); by
      // similarity to the model answers where they do not yet. A task with
      // neither never waits on a model.
      final metByKeyword = keywordGroupMatches(evaluation, text);
      final service = ref.read(meaningSignalServiceProvider);
      List<double>? parts;
      double? meaning;
      if (signalsOn && evaluation.hasMeanings) {
        parts = await service.partMeanings(
          text,
          meanings: evaluation.meanings!,
        );
      }
      if (parts != null) {
        meaning = meaningFromParts(
          metByKeyword: metByKeyword,
          entailment: parts,
        );
      } else if (signalsOn && widget.activity.accepted.isNotEmpty) {
        meaning = await service.meaning(
          text,
          modelAnswers: widget.activity.accepted,
        );
      }
      final explanation = parts == null
          ? null
          : missingPartsExplanation(
              missingMeanings(
                meanings: evaluation.meanings!,
                metByKeyword: metByKeyword,
                entailment: parts,
              ),
            );
      final packAvailable = signalsOn
          ? await ref.read(localJudgementServiceProvider).isAvailable
          : false;
      if (!mounted) return;
      _grading = false;
      final onlineAllowed = evaluation.onlineRefinement != null;
      if (onlineAllowed || packAvailable) {
        // Deferred-grading path: the rubric score and the meaning signal
        // are carried to the pending_online_refinements queue and combined
        // with the later signals (the pack's judgement, or the online
        // grammar check) in the drain. See docs/superpowers/specs/
        // 2026-09-07-offline-answer-evaluation-design.md and ADR 0013.
        submission = ActivitySubmission(
          correctness: ActivityCorrectness.notAutoGraded,
          score: rubric.score,
          rawAnswerJson: jsonEncode(text),
          pendingOnlineRefinement: true,
          onlineRefinementAllowed: onlineAllowed,
          meaningSignal: meaning,
        );
        _pendingSince = _truncatedToSeconds(DateTime.now());
      } else {
        final signals = GradingSignals(
          rubric: rubric.score ?? 0.0,
          meaning: meaning,
        );
        final finalScore = combineSignals(signals);
        final passes = passesWithSignals(
          rubricCorrect: rubric.correctness == ActivityCorrectness.correct,
          rubricScore: signals.rubric,
          finalScore: finalScore,
        );
        submission = ActivitySubmission(
          correctness: passes
              ? ActivityCorrectness.correct
              : ActivityCorrectness.incorrect,
          score: finalScore,
          rawAnswerJson: jsonEncode(text),
          criteriaScoresJson: meaning == null
              ? null
              : criteriaScoresJson(
                  signals,
                  finalScore: finalScore,
                  parts: parts,
                  explanationEn: explanation?.en,
                  explanationAr: explanation?.ar,
                ),
          explanationEn: explanation?.en,
          explanationAr: explanation?.ar,
          correctAnswerLabel: _correctAnswerLabel(),
        );
      }
    } else if (evaluation != null) {
      final result = evaluate(
        evaluation,
        text,
        context: widget.evaluationContext,
      );
      submission = ActivitySubmission(
        correctness: result.correctness,
        score: result.score,
        rawAnswerJson: jsonEncode(text),
        correctAnswerLabel: _correctAnswerLabel(),
      );
    } else if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text),
      );
      submission = ActivitySubmission(
        correctness: isCorrect
            ? ActivityCorrectness.correct
            : ActivityCorrectness.incorrect,
        score: isCorrect ? 1.0 : 0.0,
        rawAnswerJson: jsonEncode(text),
        correctAnswerLabel: _correctAnswerLabel(),
      );
    } else {
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        rawAnswerJson: jsonEncode(text),
      );
    }
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    // Never for notAutoGraded — nothing definitive to celebrate or flag
    // yet, whether it's a form-style "no automatic check exists" answer or
    // one still queued for deferred grading.
    if (submission.correctness != ActivityCorrectness.notAutoGraded) {
      if (marksAnswers(context)) {
        playFeedbackSoundSafely(
          ref.read(soundEffectsServiceProvider),
          submission.correctness == ActivityCorrectness.correct
              ? ActivityFeedbackSound.correct
              : ActivityFeedbackSound.incorrect,
        );
      }
    }
  }

  /// The pending [_submission] recast as its real graded result, once
  /// [attempt] proves to be the one this submission actually became (not a
  /// stale row from an earlier retry — see [_pendingSince]). `null` while
  /// still genuinely waiting.
  ActivitySubmission? _resolvedSubmission(ActivityAttempt? attempt) {
    if (attempt == null) return null;
    if (attempt.attemptedAt.isBefore(_pendingSince!)) return null;
    final explanation = explanationIn(attempt.criteriaScores);
    return ActivitySubmission(
      correctness: attempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: attempt.score,
      rawAnswerJson: _submission!.rawAnswerJson,
      explanationEn: explanation?.en,
      explanationAr: explanation?.ar,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The "correct answer is: ___" reveal shown on an incorrect submission.
  /// [widget.activity.accepted] wins when present (a closed-form answer
  /// list); otherwise falls back to whatever [widget.activity.evaluation]'s
  /// structured rubric can reveal (e.g. the resolved name for a
  /// `letterSequence` rubric) — `null` when neither has anything fixed to
  /// show, e.g. an open-ended `keywordChecklist` rubric.
  String? _correctAnswerLabel() {
    if (widget.activity.accepted.isNotEmpty) {
      return widget.activity.accepted.join(' / ');
    }
    final evaluation = widget.activity.evaluation;
    if (evaluation == null) return null;
    return expectedAnswerLabel(evaluation, widget.evaluationContext);
  }

  @override
  Widget build(BuildContext context) {
    final wordGuide = widget.activity.wordGuide;
    final submission = _submission;
    final displaySubmission =
        (submission != null && submission.pendingOnlineRefinement)
        ? _resolvedSubmission(
                ref
                    .watch(
                      latestAttemptProvider((
                        learnerId: widget.learnerId,
                        activityId: widget.activity.id,
                      )),
                    )
                    .value,
              ) ??
              submission
        : submission;
    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      source: widget.activity.sourceCard,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            enabled: _submission == null && !_grading,
            minLines: 5,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: activityInputDecoration(context),
            onChanged: (_) => setState(() {}),
          ),
          if (wordGuide != null && wordGuide.length == 2) ...[
            const SizedBox(height: AppSpace.sm),
            _WordGuideMeter(
              count: countWords(_controller.text),
              min: wordGuide[0],
              max: wordGuide[1],
            ),
          ],
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: displaySubmission,
        canSubmit: _controller.text.trim().isNotEmpty && !_grading,
        onSubmit: _submit,
        correctAnswerLabel: _correctAnswerLabel(),
      ),
    );
  }
}

/// The live word count against the question's suggested range: a track
/// that fills towards [max], with the target band from [min] to [max]
/// marked, turning green once the answer is long enough.
class _WordGuideMeter extends StatelessWidget {
  const _WordGuideMeter({
    required this.count,
    required this.min,
    required this.max,
  });

  final int count;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final success = theme.extension<FeedbackTheme>()!.success;
    final l10n = AppLocalizations.of(context)!;
    final inRange = count >= min;
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: tokens.textSecondary,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.activityWordCount(count),
                  style: meta?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(l10n.activityWordGuideTarget(min, max), style: meta),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: tokens.cardMuted),
                      ),
                      PositionedDirectional(
                        start: width * min / max,
                        top: 0,
                        bottom: 0,
                        end: 0,
                        child: ColoredBox(
                          color: success.withValues(alpha: 0.2),
                        ),
                      ),
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        width: width * (count.clamp(0, max) / max),
                        child: ColoredBox(
                          color: inRange ? success : tokens.primaryInk,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
