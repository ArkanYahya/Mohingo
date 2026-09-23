import 'dart:math' show min;

import '../../../../content/models/evaluation_spec.dart';
import '../activity_submission.dart';
import '../answer_matching.dart';
import '../spoken_answer.dart';
import '../spoken_numbers.dart';
import 'evaluation_context.dart';

/// Grades [answer] against [spec]. Pure and synchronous — every spec type
/// this dispatches to is fully offline. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
///
/// With [spoken], [answer] is a speech transcript and a keyword checklist
/// compares it as it was said, not as the recogniser spelled it — see
/// [SpokenAnswer] (ADR 0009). A typed answer is graded as written.
({ActivityCorrectness correctness, double? score}) evaluate(
  EvaluationSpec spec,
  String answer, {
  EvaluationContext context = const EvaluationContext.empty(),
  SpokenAnswer? spoken,
}) {
  return switch (spec) {
    NonEmptyEvaluationSpec() => _nonEmpty(answer),
    NumericRangeEvaluationSpec s => _numericRange(s, answer),
    LetterSequenceEvaluationSpec s => _letterSequence(s, answer, context),
    KeywordChecklistEvaluationSpec s => _keywordChecklist(s, answer, spoken),
  };
}

/// A short, human-readable description of what [spec] expects — shown as
/// the "the correct answer is: ..." reveal after an incorrect submission
/// (see `ActivityFeedbackBanner.correctAnswerLabel`). `null` when there's no
/// single fixed answer to reveal: [NonEmptyEvaluationSpec] accepts anything
/// non-blank, [KeywordChecklistEvaluationSpec] grades open-ended text
/// against a checklist rather than one string, and a [LetterSequenceEvaluationSpec]
/// whose reference isn't resolvable yet (an unset profile name, or a
/// previous answer that hasn't been given) has nothing concrete to show.
String? expectedAnswerLabel(EvaluationSpec spec, EvaluationContext context) {
  return switch (spec) {
    NonEmptyEvaluationSpec() => null,
    NumericRangeEvaluationSpec s => _formatRange(s),
    LetterSequenceEvaluationSpec s => _resolveReferenceText(
      s.reference,
      context,
    ),
    KeywordChecklistEvaluationSpec() => null,
  };
}

String _formatRange(NumericRangeEvaluationSpec spec) =>
    '${_formatNumber(spec.min)}–${_formatNumber(spec.max)}';

/// Drops a trailing `.0` from a whole number (`120.0` -> `120`) but keeps a
/// genuine fraction (`0.5` stays `0.5`) — [NumericRangeEvaluationSpec]'s
/// bounds are always `double`, even when the bundle authored them as plain
/// integers (e.g. an age range), and showing "1.0–120.0" to a learner would
/// look like a typo.
String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

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
  // In digits or in words: a recogniser returns "25" for one speaker and
  // "twenty-five" for the next, and a learner may type either.
  final value = spokenNumberIn(answer);
  if (value == null) {
    return (correctness: ActivityCorrectness.incorrect, score: 0.0);
  }
  final isCorrect = value >= spec.min && value <= spec.max;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

/// The raw text [reference] points at, or `null` if it isn't resolvable yet
/// (an unset profile name, or a previous-answer reference whose activity
/// hasn't been answered — see the callers for how each handles that).
String? _resolveReferenceText(
  LetterSequenceReference reference,
  EvaluationContext context,
) {
  return switch (reference) {
    ProfileNameReference() => context.profileName,
    PreviousAnswerReference(:final activityId) =>
      context.previousAnswers[activityId],
    LiteralReference(:final text) => text,
  };
}

({ActivityCorrectness correctness, double? score}) _letterSequence(
  LetterSequenceEvaluationSpec spec,
  String answer,
  EvaluationContext context,
) {
  final reference = _resolveReferenceText(spec.reference, context);

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
bool _mentionsKeyword(String answer, String keyword, SpokenAnswer? spoken) {
  final trimmed = keyword.trim();
  if (trimmed.isEmpty) return false;
  if (spoken != null) return _mentionsSpokenKeyword(answer, trimmed, spoken);
  final body = trimmed.split(_whitespaceRun).map(RegExp.escape).join(r'\s+');
  final prefix = _leadingWordCharacter.hasMatch(trimmed) ? r'\b' : '';
  final suffix = _trailingWordCharacter.hasMatch(trimmed) ? r'\b' : '';
  return RegExp('$prefix$body$suffix', caseSensitive: false).hasMatch(answer);
}

/// The spoken form of [_mentionsKeyword]: the keyword's words, as said,
/// appear in order somewhere in the transcript's words, each pair judged
/// by [spokenWordsMatch] — so "sara" is met by "Sarah", "at seven" by
/// "at 7", "two" by "to". Both sides go through the same normalisation
/// (contractions spelled out, punctuation dropped), which is why a rubric's
/// "she's my friend" also meets a transcript's "she is my friend".
bool _mentionsSpokenKeyword(
  String answer,
  String keyword,
  SpokenAnswer spoken,
) {
  final wanted = normalizedWords(keyword, spoken: true);
  final heard = normalizedWords(answer, spoken: true);
  if (wanted.isEmpty || heard.length < wanted.length) return false;
  for (var start = 0; start + wanted.length <= heard.length; start++) {
    var all = true;
    for (var i = 0; i < wanted.length; i++) {
      if (!spokenWordsMatch(wanted[i], heard[start + i], spoken)) {
        all = false;
        break;
      }
    }
    if (all) return true;
  }
  return false;
}

/// The score is measured against the rubric's own pass bar
/// ([KeywordChecklistEvaluationSpec.minGroupsMatched]), not against the
/// total number of groups.
///
/// A rubric may legitimately ask for "any 2 of these 3 things" (the real
/// `A1-U5-L6-A05` does). Scoring `matched / requiredGroups.length` would
/// give such an answer 0.667 — `correct` by the rubric, yet below
/// `MasteryPolicy.minimumObjectiveScore` (0.75), so
/// `MasteryAggregationService` (which reads `score` before `isCorrect`)
/// would refuse to count a rubric-passing answer as qualifying evidence.
/// Dividing by the pass bar instead means exactly meeting it always scores
/// a full 1.0, falling short scores proportionally, and covering *more*
/// groups than asked never exceeds 1.0.
({ActivityCorrectness correctness, double? score}) _keywordChecklist(
  KeywordChecklistEvaluationSpec spec,
  String answer,
  SpokenAnswer? spoken,
) {
  final matchedGroups = spec.requiredGroups
      .where((group) => group.any((kw) => _mentionsKeyword(answer, kw, spoken)))
      .length;
  final isCorrect = matchedGroups >= spec.minGroupsMatched;
  // Guards both a rubric with no groups at all and a non-positive pass bar
  // (which every answer clears, and which would divide by zero).
  final score = spec.requiredGroups.isEmpty || spec.minGroupsMatched <= 0
      ? (isCorrect ? 1.0 : 0.0)
      : min(1.0, matchedGroups / spec.minGroupsMatched);
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: score,
  );
}
