import '../../../../content/models/evaluation_spec.dart';
import '../activity_submission.dart';
import '../answer_matching.dart';
import 'evaluation_context.dart';

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

  // Normalize *before* the emptiness check, not after: this comparison only
  // understands Latin letters, so a reference with none of them — an Arabic
  // name like "علي", which this app's Arabic-speaking learners will
  // plausibly save in Settings — is just as unusable as a missing one, even
  // though its raw string is non-empty. Checking the raw string here would
  // silently compare '' against the answer and mark every attempt wrong
  // forever.
  final resolved = reference == null ? null : lettersOnly(reference);

  if (resolved == null || resolved.isEmpty) {
    // A profile name that hasn't been set yet (or isn't spellable in Latin
    // letters) is a normal, expected state — soften to a non-empty check
    // rather than blocking the objective outright. A missing previous-answer
    // reference is rarer: the lesson player rehydrates earlier answers from
    // recorded attempts when resuming mid-lesson, so this is reached only if
    // that earlier attempt genuinely has no stored text answer (or the
    // rubric points at an activity that was never answered). That can't be
    // graded either way, so it's left un-auto-graded rather than silently
    // treated as a pass.
    if (spec.reference is ProfileNameReference) return _nonEmpty(answer);
    return (correctness: ActivityCorrectness.notAutoGraded, score: null);
  }

  final isCorrect = resolved == lettersOnly(answer);
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

final _leadingWordCharacter = RegExp(r'^\w');
final _trailingWordCharacter = RegExp(r'\w$');
final _whitespaceRun = RegExp(r'\s+');

/// Whether [answer] mentions [keyword] as a whole word (or whole phrase),
/// not merely as a substring.
///
/// A plain `contains` would let a two-letter keyword like "hi" match inside
/// "this", "which" or "history", handing a learner a pass for a sentence
/// that never greeted anyone — so each keyword is anchored with word
/// boundaries. Multi-word phrases ("good morning") match across any run of
/// whitespace, and boundaries are only applied on an edge that's actually a
/// word character, so a keyword starting or ending in punctuation — or one
/// written in a non-Latin script, where Dart's ASCII `\b` would never
/// match — still behaves like the old substring check rather than silently
/// never matching.
bool _mentionsKeyword(String answer, String keyword) {
  final trimmed = keyword.trim();
  if (trimmed.isEmpty) return false;
  final body = trimmed.split(_whitespaceRun).map(RegExp.escape).join(r'\s+');
  final prefix = _leadingWordCharacter.hasMatch(trimmed) ? r'\b' : '';
  final suffix = _trailingWordCharacter.hasMatch(trimmed) ? r'\b' : '';
  return RegExp('$prefix$body$suffix', caseSensitive: false).hasMatch(answer);
}

({ActivityCorrectness correctness, double? score}) _keywordChecklist(
  KeywordChecklistEvaluationSpec spec,
  String answer,
) {
  final matchedGroups = spec.requiredGroups
      .where((group) => group.any((kw) => _mentionsKeyword(answer, kw)))
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
