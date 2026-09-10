import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';

/// Renders a `match` activity: tap a left item, then its matching right
/// item, to pair them up.
class MatchActivityView extends ConsumerStatefulWidget {
  const MatchActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    this.suppressIncorrectBanner = false,
    super.key,
  });

  final MatchActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  /// True only when rendered by the live lesson player — see
  /// [ActivitySubmitOrFeedback.suppressIncorrectBanner].
  final bool suppressIncorrectBanner;

  @override
  ConsumerState<MatchActivityView> createState() => _MatchActivityViewState();
}

class _MatchActivityViewState extends ConsumerState<MatchActivityView> {
  late final List<String> _rightShuffled =
      widget.activity.pairs.map((pair) => pair[1]).toList()
        ..shuffle(Random(widget.activity.pairs.length));

  final Map<String, String> _userMatches = {}; // left -> right
  String? _pendingLeft;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeMatches(reviewAttempt.rawAnswer);
    if (decoded != null) _userMatches.addAll(decoded);
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

  Map<String, String>? _decodeMatches(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is Map ? Map<String, String>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  bool get _isComplete => _userMatches.length == widget.activity.pairs.length;

  void _tapLeft(String left) {
    if (_submission != null) return;
    setState(() => _pendingLeft = _pendingLeft == left ? null : left);
  }

  void _tapRight(String right) {
    if (_submission != null || _pendingLeft == null) return;
    setState(() {
      _userMatches[_pendingLeft!] = right;
      _pendingLeft = null;
    });
    // The last pair completes the answer — submit immediately, no
    // separate Check tap needed.
    if (_isComplete) _submit();
  }

  void _submit() {
    if (!_isComplete || _submission != null) return;
    final allCorrect = widget.activity.pairs.every(
      (pair) => _userMatches[pair[0]] == pair[1],
    );
    final correctPairLabel = widget.activity.pairs
        .map((p) => '${p[0]} → ${p[1]}')
        .join(', ');
    final submission = ActivitySubmission(
      correctness: allCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: allCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_userMatches),
      correctAnswerLabel: correctPairLabel,
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    playFeedbackSoundSafely(
      ref.read(soundEffectsServiceProvider),
      allCorrect
          ? ActivityFeedbackSound.correct
          : ActivityFeedbackSound.incorrect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lefts = widget.activity.pairs.map((p) => p[0]).toList();
    final correctPairLabel = widget.activity.pairs
        .map((p) => '${p[0]} → ${p[1]}')
        .join(', ');

    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final left in lefts)
                  _MatchChip(
                    label: left,
                    selected: _pendingLeft == left,
                    matched: _userMatches.containsKey(left),
                    onTap: _submission == null ? () => _tapLeft(left) : null,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final right in _rightShuffled)
                  _MatchChip(
                    label: right,
                    selected: false,
                    matched: _userMatches.containsValue(right),
                    onTap: _submission == null ? () => _tapRight(right) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
      // No Check button is ever reached in practice — matching the last
      // pair (_tapRight) always submits before this would render; kept
      // as a safety net, matching the shared ActivitySubmitOrFeedback
      // contract every activity view uses.
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _isComplete,
        onSubmit: _submit,
        correctAnswerLabel: correctPairLabel,
        suppressIncorrectBanner: widget.suppressIncorrectBanner,
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool matched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : (matched
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainer),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(label, textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );
  }
}
