import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/evaluation_spec.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
import '../../providers/online_refinement_providers.dart';
import '../activity_chrome.dart';

/// Renders a `write` activity: a free-text response, with a suggested word
/// count when [WriteActivity.wordGuide] is declared.
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
    _submission = ActivitySubmission(
      correctness: switch (reviewAttempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      },
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
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

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || _submission != null) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
    if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text),
      );
      submission = ActivitySubmission(
        correctness: isCorrect
            ? ActivityCorrectness.correct
            : ActivityCorrectness.incorrect,
        score: isCorrect ? 1.0 : 0.0,
        rawAnswerJson: jsonEncode(text),
      );
    } else if (evaluation is KeywordChecklistEvaluationSpec &&
        evaluation.onlineRefinement != null) {
      // Open-ended, deferred-grading path: the local score is computed now
      // but never used as the graded score directly — it's carried through
      // to the pending_online_refinements queue and combined with a free
      // online grammar-quality pass once the device is online. See
      // docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
      final localResult = evaluate(evaluation, text);
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        score: localResult.score,
        rawAnswerJson: jsonEncode(text),
        pendingOnlineRefinement: true,
      );
      _pendingSince = _truncatedToSeconds(DateTime.now());
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
      );
    } else {
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        rawAnswerJson: jsonEncode(text),
      );
    }
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }

  /// The pending [_submission] recast as its real graded result, once
  /// [attempt] proves to be the one this submission actually became (not a
  /// stale row from an earlier retry — see [_pendingSince]). `null` while
  /// still genuinely waiting.
  ActivitySubmission? _resolvedSubmission(ActivityAttempt? attempt) {
    if (attempt == null) return null;
    if (attempt.attemptedAt.isBefore(_pendingSince!)) return null;
    return ActivitySubmission(
      correctness: attempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: attempt.score,
      rawAnswerJson: _submission!.rawAnswerJson,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      help: wordGuide != null && wordGuide.length == 2
          ? Text(
              AppLocalizations.of(context)!
                  .activityWordGuide(wordGuide[0], wordGuide[1]),
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
      body: TextField(
        controller: _controller,
        enabled: _submission == null,
        maxLines: 4,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: displaySubmission,
        canSubmit: _controller.text.trim().isNotEmpty,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.accepted.isNotEmpty
            ? widget.activity.accepted.join(' / ')
            : null,
      ),
    );
  }
}
