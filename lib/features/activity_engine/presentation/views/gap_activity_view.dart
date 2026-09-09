import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../activity_chrome.dart';

/// Renders a `gap` activity: a sentence with a `___` blank, filled by
/// picking one of [GapActivity.options].
class GapActivityView extends StatefulWidget {
  const GapActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final GapActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<GapActivityView> createState() => _GapActivityViewState();
}

class _GapActivityViewState extends State<GapActivityView> {
  String? _selected;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _selected = _decodeSelection(reviewAttempt.rawAnswer);
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

  String? _decodeSelection(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _submit() {
    if (_selected == null || _submission != null) return;
    final isCorrect = _selected == widget.activity.answer;
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_selected),
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayText = widget.activity.text.replaceFirst(
      '___',
      _selected ?? '___',
    );

    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayText,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in widget.activity.options)
                ChoiceChip(
                  label: Text(option),
                  selected: _selected == option,
                  onSelected: _submission == null
                      ? (_) => setState(() => _selected = option)
                      : null,
                ),
            ],
          ),
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _selected != null,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.answer,
      ),
    );
  }
}
