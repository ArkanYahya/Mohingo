import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../activity_chrome.dart';

/// Renders a `write` activity: a free-text response, with a suggested word
/// count when [WriteActivity.wordGuide] is declared.
///
/// When [WriteActivity.accepted] lists specific acceptable answers (short,
/// closed-form writing tasks), the response is checked against them via
/// [answersMatch] — case-insensitively, tolerant of harmless punctuation
/// and apostrophe-style differences; otherwise (open-ended tasks relying on
/// [WriteActivity.evaluation], a rubric id) the submission is recorded as
/// [ActivityCorrectness.notAutoGraded] — writing tasks generally need a
/// task-specific rubric, not an automatic right/wrong check. See
/// docs/DATA_MODEL.md.
class WriteActivityView extends StatefulWidget {
  const WriteActivityView({
    required this.activity,
    required this.onSubmitted,
    super.key,
  });

  final WriteActivity activity;
  final OnActivitySubmitted onSubmitted;

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
