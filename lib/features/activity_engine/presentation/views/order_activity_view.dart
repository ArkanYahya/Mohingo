import 'dart:convert';

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

/// Renders an `order` activity: tap words in order to build the sentence
/// on ruled lines, tap a placed word to send it back, then Check.
///
/// Used words leave an empty slot of the same size in the word bank, so the
/// remaining words never jump around mid-answer.
class OrderActivityView extends ConsumerStatefulWidget {
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
  ConsumerState<OrderActivityView> createState() => _OrderActivityViewState();
}

class _OrderActivityViewState extends ConsumerState<OrderActivityView> {
  /// Indices into [OrderActivity.tokens], in the order they were placed —
  /// a sentence can repeat a word, so a word alone doesn't say which bank
  /// tile it came from.
  final List<int> _placed = [];
  ActivitySubmission? _submission;

  List<String> get _tokens => widget.activity.tokens;

  List<String> get _placedWords => [for (final i in _placed) _tokens[i]];

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    for (final word in _decodeOrder(reviewAttempt.rawAnswer) ?? const []) {
      final index = _unplacedIndexOf(word);
      if (index != -1) _placed.add(index);
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

  int _unplacedIndexOf(String word) {
    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i] == word && !_placed.contains(i)) return i;
    }
    return -1;
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

  bool get _isComplete => _placed.length == _tokens.length;

  void _place(int index) {
    if (_submission != null || _placed.contains(index)) return;
    setState(() => _placed.add(index));
  }

  void _unplace(int index) {
    if (_submission != null) return;
    setState(() => _placed.remove(index));
  }

  void _submit() {
    if (!_isComplete || _submission != null) return;
    final isCorrect =
        _placedWords.join(' ') == widget.activity.answer.join(' ');
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_placedWords),
      correctAnswerLabel: widget.activity.answer.join(' '),
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    if (marksAnswers(context)) {
      playFeedbackSoundSafely(
        ref.read(soundEffectsServiceProvider),
        isCorrect
            ? ActivityFeedbackSound.correct
            : ActivityFeedbackSound.incorrect,
      );
    }
  }

  /// After Check, each placed word shows whether it's in the right place.
  AnswerTileState _placedState(int position) {
    // In a test the sentence stays as built — never marked.
    if (_submission == null || !marksAnswers(context)) {
      return AnswerTileState.idle;
    }
    final answer = widget.activity.answer;
    return position < answer.length &&
            _tokens[_placed[position]] == answer[position]
        ? AnswerTileState.correct
        : AnswerTileState.incorrect;
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submission != null;
    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RuledAnswerArea(
            emptyHint: _placed.isEmpty && !submitted
                ? AppLocalizations.of(context)!.activityOrderEmptyHint
                : null,
            children: [
              for (var position = 0; position < _placed.length; position++)
                ActivityWordTile(
                  label: _tokens[_placed[position]],
                  state: _placedState(position),
                  onTap: submitted ? null : () => _unplace(_placed[position]),
                ),
            ],
          ),
          // Once checked, every word is in the sentence — a bank of empty
          // slots would only be clutter.
          if (!submitted) ...[
            const SizedBox(height: AppSpace.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (var i = 0; i < _tokens.length; i++)
                  if (_placed.contains(i))
                    ActivityWordTileGhost(label: _tokens[i])
                  else
                    ActivityWordTile(label: _tokens[i], onTap: () => _place(i)),
              ],
            ),
          ],
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _isComplete,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.answer.join(' '),
      ),
    );
  }
}

/// The sentence being built: word tiles sitting on ruled lines, like a
/// line of an exercise book, at least two lines tall so the area doesn't
/// grow as the first words land.
class _RuledAnswerArea extends StatelessWidget {
  const _RuledAnswerArea({required this.children, this.emptyHint});

  final List<Widget> children;
  final String? emptyHint;

  static const double runSpacing = AppSpace.sm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final tileHeight = ActivityWordTile.heightOf(context);
    final pitch = tileHeight + runSpacing;

    return CustomPaint(
      painter: _RulesPainter(
        color: tokens.border,
        tileHeight: tileHeight,
        pitch: pitch,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 2 * pitch),
        child: Padding(
          padding: const EdgeInsets.only(bottom: runSpacing),
          child: emptyHint != null
              ? SizedBox(
                  height: tileHeight,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      emptyHint!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                )
              : Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: runSpacing,
                  // The sentence is English: it always builds left-to-right.
                  textDirection: TextDirection.ltr,
                  children: children,
                ),
        ),
      ),
    );
  }
}

class _RulesPainter extends CustomPainter {
  _RulesPainter({
    required this.color,
    required this.tileHeight,
    required this.pitch,
  });

  final Color color;
  final double tileHeight;
  final double pitch;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (
      var y = tileHeight + _RuledAnswerArea.runSpacing / 2;
      y < size.height;
      y += pitch
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulesPainter oldDelegate) =>
      color != oldDelegate.color ||
      tileHeight != oldDelegate.tileHeight ||
      pitch != oldDelegate.pitch;
}
