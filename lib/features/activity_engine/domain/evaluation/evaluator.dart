import '../activity_submission.dart';
import '../answer_matching.dart';
import 'evaluation_context.dart';
import 'evaluation_spec.dart';

final _numberPattern = RegExp(r'\d+(\.\d+)?');

/// Grades [answer] against [spec]. Pure and synchronous — every spec type
/// this dispatches to is fully offline. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
({ActivityCorrectness correctness, double? score}) evaluate(
  EvaluationSpec spec,
  String answer, {
  EvaluationContext context = const EvaluationContext.empty(),
}) {
  return switch (spec) {
    NonEmptyEvaluationSpec() => _nonEmpty(answer),
    NumericRangeEvaluationSpec s => _numericRange(s, answer),
    LetterSequenceEvaluationSpec s => _letterSequence(s, answer, context),
    KeywordChecklistEvaluationSpec s => _keywordChecklist(s, answer),
  };
}

({ActivityCorrectness correctness, double? score}) _nonEmpty(String answer) {
  final isCorrect = answer.trim().isNotEmpty;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _numericRange(
  NumericRangeEvaluationSpec spec,
  String answer,
) {
  final match = _numberPattern.firstMatch(answer);
  if (match == null) {
    return (correctness: ActivityCorrectness.incorrect, score: 0.0);
  }
  final value = double.parse(match.group(0)!);
  final isCorrect = value >= spec.min && value <= spec.max;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _letterSequence(
  LetterSequenceEvaluationSpec spec,
  String answer,
  EvaluationContext context,
) {
  final reference = switch (spec.reference) {
    ProfileNameReference() => context.profileName,
    PreviousAnswerReference(:final activityId) =>
      context.previousAnswers[activityId],
    LiteralReference(:final text) => text,
  };

  if (reference == null || reference.trim().isEmpty) {
    // A profile name that hasn't been set yet is a normal, expected state
    // (the learner may not have visited Settings) — soften to a
    // non-empty check rather than blocking. A missing previous-answer
    // reference should never happen in a correctly authored lesson (the
    // referenced activity is always earlier in the same lesson), so it's
    // left un-auto-graded rather than silently treated as a pass.
    if (spec.reference is ProfileNameReference) return _nonEmpty(answer);
    return (correctness: ActivityCorrectness.notAutoGraded, score: null);
  }

  final isCorrect = lettersOnlyMatch(reference, answer);
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _keywordChecklist(
  KeywordChecklistEvaluationSpec spec,
  String answer,
) {
  final normalized = answer.toLowerCase();
  final matchedGroups = spec.requiredGroups
      .where(
        (group) => group.any((kw) => normalized.contains(kw.toLowerCase())),
      )
      .length;
  final isCorrect = matchedGroups >= spec.minGroupsMatched;
  final score = spec.requiredGroups.isEmpty
      ? (isCorrect ? 1.0 : 0.0)
      : matchedGroups / spec.requiredGroups.length;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: score,
  );
}
