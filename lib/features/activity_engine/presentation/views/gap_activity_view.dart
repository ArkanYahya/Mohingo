import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../activity_chrome.dart';

/// Renders a `gap` activity: a sentence with a `___` blank, filled by
/// picking one of [GapActivity.options].
class GapActivityView extends StatefulWidget {
  GapActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    Random? random,
    super.key,
  }) : _random = random ?? Random();

  final GapActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  /// Used once, at first build, to shuffle [GapActivity.options] for
  /// display — see [_GapActivityViewState._displayOptions]. Injectable so a
  /// test can assert on a deterministic shuffle order; production call
  /// sites always omit it, getting a genuinely random order on every mount.
  final Random _random;

  @override
  State<GapActivityView> createState() => _GapActivityViewState();
}

class _GapActivityViewState extends State<GapActivityView> {
  String? _selected;
  ActivitySubmission? _submission;

  /// [GapActivity.options] shuffled once per mount — same rationale as
  /// `ChoiceActivityView._displayOptions`: real A1 content overwhelmingly
  /// puts the correct answer first, so the raw order is guessable without
  /// a shuffle. Stable across this instance's own rebuilds; only a fresh
  /// mount reshuffles.
  late final List<String> _displayOptions = List<String>.from(
    widget.activity.options,
  )..shuffle(widget._random);

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
              for (final option in _displayOptions)
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
