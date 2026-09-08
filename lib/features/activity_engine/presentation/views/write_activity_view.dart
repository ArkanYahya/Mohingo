import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/evaluation_spec.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
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
class WriteActivityView extends StatefulWidget {
  const WriteActivityView({
    required this.activity,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    super.key,
  });

  final WriteActivity activity;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;

  @override
  State<WriteActivityView> createState() => _WriteActivityViewState();
}

class _WriteActivityViewState extends State<WriteActivityView> {
  final _controller = TextEditingController();
  ActivitySubmission? _submission;

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordGuide = widget.activity.wordGuide;
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
        submission: _submission,
        canSubmit: _controller.text.trim().isNotEmpty,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.accepted.isNotEmpty
            ? widget.activity.accepted.join(' / ')
            : null,
      ),
    );
  }
}
