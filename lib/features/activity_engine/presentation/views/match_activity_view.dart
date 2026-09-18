import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';
import '../widgets/activity_word_tile.dart';
import '../widgets/answer_tile_state.dart';

/// Renders a `match` activity: tap an item in either column, then its
/// partner in the other, to pair them; tap a paired item to undo the pair;
/// Check once every item is paired.
///
/// Pairs share a number badge and a neutral tint — never green, which
/// would reveal correctness before Check. After Check each pair turns
/// right or wrong on both sides.
class MatchActivityView extends ConsumerStatefulWidget {
  const MatchActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
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

  @override
  ConsumerState<MatchActivityView> createState() => _MatchActivityViewState();
}

class _MatchActivityViewState extends ConsumerState<MatchActivityView> {
  late final List<String> _lefts = [
    for (final pair in widget.activity.pairs) pair[0],
  ];
  late final List<String> _rights = [
    for (final pair in widget.activity.pairs) pair[1],
  ]..shuffle(Random(widget.activity.pairs.length));

  /// Left index → right index. Indices, not labels, so a repeated word in
  /// one column still pairs with exactly the tile the learner tapped.
  final Map<int, int> _pairs = {};
  int? _pendingLeft;
  int? _pendingRight;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final recorded = _decodeMatches(reviewAttempt.rawAnswer) ?? const {};
    for (var left = 0; left < _lefts.length; left++) {
      final rightLabel = recorded[_lefts[left]];
      if (rightLabel == null) continue;
      for (var right = 0; right < _rights.length; right++) {
        if (_rights[right] == rightLabel && !_pairs.containsValue(right)) {
          _pairs[left] = right;
          break;
        }
      }
    }
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

  bool get _isComplete => _pairs.length == _lefts.length;

  String get _correctPairLabel =>
      widget.activity.pairs.map((p) => '${p[0]} → ${p[1]}').join(', ');

  int? _leftPairedWith(int right) {
    for (final entry in _pairs.entries) {
      if (entry.value == right) return entry.key;
    }
    return null;
  }

  void _tapLeft(int left) {
    if (_submission != null) return;
    setState(() {
      if (_pairs.containsKey(left)) {
        _pairs.remove(left);
      } else if (_pendingRight != null) {
        _pairs[left] = _pendingRight!;
      } else {
        _pendingLeft = _pendingLeft == left ? null : left;
        return;
      }
      _pendingLeft = null;
      _pendingRight = null;
    });
  }

  void _tapRight(int right) {
    if (_submission != null) return;
    setState(() {
      final pairedLeft = _leftPairedWith(right);
      if (pairedLeft != null) {
        _pairs.remove(pairedLeft);
      } else if (_pendingLeft != null) {
        _pairs[_pendingLeft!] = right;
      } else {
        _pendingRight = _pendingRight == right ? null : right;
        return;
      }
      _pendingLeft = null;
      _pendingRight = null;
    });
  }

  bool _isRightPair(int left) =>
      _pairs[left] != null &&
      _rights[_pairs[left]!] == widget.activity.pairs[left][1];

  void _submit() {
    if (!_isComplete || _submission != null) return;
    final allCorrect = [for (var left = 0; left < _lefts.length; left++) left]
        .every(_isRightPair);
    final submission = ActivitySubmission(
      correctness: allCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: allCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode({
        for (var left = 0; left < _lefts.length; left++)
          if (_pairs[left] != null) _lefts[left]: _rights[_pairs[left]!],
      }),
      correctAnswerLabel: _correctPairLabel,
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

  AnswerTileState _stateFor({required int? pairedLeft, required bool pending}) {
    if (_submission != null) {
      if (pairedLeft == null) return AnswerTileState.dimmed;
      return _isRightPair(pairedLeft)
          ? AnswerTileState.correct
          : AnswerTileState.incorrect;
    }
    if (pending) return AnswerTileState.selected;
    return pairedLeft != null ? AnswerTileState.paired : AnswerTileState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final submitted = _submission != null;

    Widget leftTile(int left) {
      final paired = _pairs.containsKey(left);
      return ActivityWordTile(
        label: _lefts[left],
        expand: true,
        badge: paired ? left + 1 : null,
        state: _stateFor(
          pairedLeft: paired ? left : null,
          pending: _pendingLeft == left,
        ),
        onTap: submitted ? null : () => _tapLeft(left),
      );
    }

    Widget rightTile(int right) {
      final pairedLeft = _leftPairedWith(right);
      return ActivityWordTile(
        label: _rights[right],
        expand: true,
        badge: pairedLeft == null ? null : pairedLeft + 1,
        state: _stateFor(
          pairedLeft: pairedLeft,
          pending: _pendingRight == right,
        ),
        onTap: submitted ? null : () => _tapRight(right),
      );
    }

    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < _lefts.length; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: leftTile(row)),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: rightTile(row)),
                  ],
                ),
              ),
            ),
          if (!submitted) ...[
            const SizedBox(height: AppSpace.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_rounded, size: 16, color: tokens.textSecondary),
                const SizedBox(width: AppSpace.xs - 2),
                Text(
                  AppLocalizations.of(context)!
                      .activityMatchProgress(_pairs.length, _lefts.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _isComplete,
        onSubmit: _submit,
        correctAnswerLabel: _correctPairLabel,
      ),
    );
  }
}
