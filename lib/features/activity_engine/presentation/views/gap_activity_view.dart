import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/sound_effects_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../activity_chrome.dart';
import '../widgets/activity_word_tile.dart';
import '../widgets/answer_tile_state.dart';

/// Renders a `gap` activity: a sentence with a `___` blank, filled by
/// picking one of [GapActivity.options]; Check submits the pick.
class GapActivityView extends ConsumerStatefulWidget {
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
  ConsumerState<GapActivityView> createState() => _GapActivityViewState();
}

class _GapActivityViewState extends ConsumerState<GapActivityView> {
  /// Index into [_displayOptions] — options can repeat a word (a real
  /// content quirk), so a label alone doesn't identify which tile was
  /// picked.
  int? _selectedIndex;
  ActivitySubmission? _submission;

  String? get _selected =>
      _selectedIndex == null ? null : _displayOptions[_selectedIndex!];

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
    final recorded = _decodeSelection(reviewAttempt.rawAnswer);
    final index = recorded == null ? -1 : _displayOptions.indexOf(recorded);
    _selectedIndex = index == -1 ? null : index;
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

  void _select(int index) => setState(() => _selectedIndex = index);

  void _submit() {
    if (_selected == null || _submission != null) return;
    final isCorrect = _selected == widget.activity.answer;
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_selected),
      correctAnswerLabel: widget.activity.answer,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final submitted = _submission != null;
    final parts = widget.activity.text.split('___');
    final sentenceStyle = theme.textTheme.titleMedium?.copyWith(
      color: tokens.textPrimary,
      fontSize: 18,
      height: 1.5,
    );
    // In a test the choice stays selected — never marked.
    final marked = submitted && marksAnswers(context);
    final blankColor = switch (marked) {
      false => tokens.primaryInk,
      true when _selected == widget.activity.answer => answerTileColors(
        context,
        AnswerTileState.correct,
      ).outline,
      true => answerTileColors(context, AnswerTileState.incorrect).outline,
    };

    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: tokens.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: parts.first),
                    TextSpan(
                      text: _selected ?? '___',
                      style: _selected == null
                          ? TextStyle(color: tokens.textSecondary)
                          : TextStyle(
                              color: blankColor,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: blankColor,
                              decorationThickness: 2,
                            ),
                    ),
                    if (parts.length > 1)
                      TextSpan(text: parts.skip(1).join('___')),
                  ],
                ),
                textDirection: TextDirection.ltr,
                style: sentenceStyle,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (var i = 0; i < _displayOptions.length; i++)
                ActivityWordTile(
                  label: _displayOptions[i],
                  state: singleChoiceState(
                    submitted: marked,
                    isSelected: i == _selectedIndex,
                    isCorrect: _displayOptions[i] == widget.activity.answer,
                  ),
                  onTap: submitted ? null : () => _select(i),
                ),
            ],
          ),
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _selectedIndex != null,
        onSubmit: _submit,
        correctAnswerLabel: widget.activity.answer,
      ),
    );
  }
}
