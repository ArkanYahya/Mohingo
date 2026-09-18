import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';

/// How an answer control looks. Before Check it is [idle], [selected] or
/// [paired] (a matched pair, not yet graded); after Check the right answer
/// is [correct], a wrong pick [incorrect], and the rest [dimmed].
///
/// Correctness is never shown before Check — see docs/ARCHITECTURE.md's
/// non-negotiable rules — which is why [paired] is its own neutral state
/// rather than a green one.
enum AnswerTileState { idle, selected, paired, correct, incorrect, dimmed }

/// The state of one option in a single-answer question.
AnswerTileState singleChoiceState({
  required bool submitted,
  required bool isSelected,
  required bool isCorrect,
}) {
  if (!submitted) {
    return isSelected ? AnswerTileState.selected : AnswerTileState.idle;
  }
  if (isCorrect) return AnswerTileState.correct;
  return isSelected ? AnswerTileState.incorrect : AnswerTileState.dimmed;
}

/// Fill, outline and text colours for an answer control in [state].
///
/// Correct is the semantic green and incorrect the error red, never the
/// learner's brand colour — see FeedbackTheme.
({Color fill, Color outline, double outlineWidth, Color foreground})
answerTileColors(BuildContext context, AnswerTileState state) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppTokens>()!;
  final feedback = theme.extension<FeedbackTheme>()!;
  final colorScheme = theme.colorScheme;
  return switch (state) {
    AnswerTileState.idle || AnswerTileState.dimmed => (
      fill: tokens.card,
      outline: tokens.border,
      outlineWidth: 1,
      foreground: tokens.textPrimary,
    ),
    AnswerTileState.selected => (
      fill: tokens.primaryInkTint,
      outline: tokens.primaryInk,
      outlineWidth: 2,
      foreground: tokens.textPrimary,
    ),
    AnswerTileState.paired => (
      fill: tokens.primaryInkTint,
      outline: tokens.primaryInkTint,
      outlineWidth: 1,
      foreground: tokens.textPrimary,
    ),
    AnswerTileState.correct => (
      fill: feedback.successContainer,
      outline: feedback.success,
      outlineWidth: 2,
      foreground: feedback.onSuccessContainer,
    ),
    AnswerTileState.incorrect => (
      fill: colorScheme.errorContainer,
      outline: colorScheme.error,
      outlineWidth: 2,
      foreground: colorScheme.onErrorContainer,
    ),
  };
}
