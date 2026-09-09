import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../activity_chrome.dart';

/// Renders an `order` activity: tap tokens in order to build the sentence.
class OrderActivityView extends StatefulWidget {
  const OrderActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final OrderActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<OrderActivityView> createState() => _OrderActivityViewState();
}

class _OrderActivityViewState extends State<OrderActivityView> {
  final List<String> _placed = [];
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeOrder(reviewAttempt.rawAnswer);
    if (decoded != null) _placed.addAll(decoded);
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

  List<String>? _decodeOrder(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is List ? List<String>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  List<String> get _remaining {
    final remaining = [...widget.activity.tokens];
    for (final token in _placed) {
      remaining.remove(token);
    }
    return remaining;
  }

  void _place(String token) {
    if (_submission != null) return;
    setState(() => _placed.add(token));
    // The last token placed completes the answer — submit immediately,
    // no separate Check tap needed.
    if (_placed.length == widget.activity.tokens.length) _submit();
  }

  void _removeLast() {
    if (_submission != null || _placed.isEmpty) return;
    setState(() => _placed.removeLast());
  }

  void _submit() {
    if (_placed.length != widget.activity.tokens.length ||
        _submission != null) {
      return;
    }
    final isCorrect = _placed.join(' ') == widget.activity.answer.join(' ');
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_placed),
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final token in _placed)
                  ActionChip(
                    label: Text(token),
                    onPressed: _submission == null ? _removeLast : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final token in _remaining)
                ActionChip(
                  label: Text(token),
                  onPressed: _submission == null ? () => _place(token) : null,
                ),
            ],
          ),
        ],
      ),
      // No Check button is ever reached in practice — placing the last
      // token (_place) always submits before this would render; kept as
      // a safety net, matching the shared ActivitySubmitOrFeedback
      // contract every activity view uses.
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _placed.length == widget.activity.tokens.length,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.answer.join(' '),
      ),
    );
  }
}
