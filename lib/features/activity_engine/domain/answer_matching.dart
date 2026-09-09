/// Whether [given] (a learner's typed or transcribed answer) matches
/// [accepted] (one entry from an activity's `accepted` list) closely enough
/// to count as correct.
///
/// Accepts capitalization and harmless punctuation/spacing variation when
/// the meaning is otherwise identical — a learner should not be marked
/// wrong for typing "thanks" against an accepted answer authored as
/// "Thanks.", or for a speech transcript that drops terminal punctuation
/// entirely. Also handles the letter-spelling case ("Spell the name Ali."),
/// where the shipped content's `accepted` answers are written
/// hyphen-joined (e.g. `"A-L-I"`) but a spoken or typed answer commonly
/// comes back space-separated ("a l i") or run together ("ali").
bool answersMatch(String accepted, String given) {
  if (_normalize(accepted) == _normalize(given)) return true;

  if (_isLetterSpellingAnswer(accepted)) {
    return lettersOnlyMatch(accepted, given);
  }

  return false;
}

final _curlyApostrophes = RegExp('[‘’ʼ]');
final _sentencePunctuation = RegExp(r'[.!?,;:]+');
final _whitespaceRun = RegExp(r'\s+');

// Expands the small set of be-verb/negation contractions this A1 content
// actually uses (see the curriculum's own `A1.G.BE.*` grammar entries) to
// their full form, so an accepted answer authored with a contraction
// matches a given answer that spells it out, and vice versa — both sides
// run through the same expansion before comparing. `'s` is only expanded
// after this closed set of pronoun/wh-word subjects, never after an
// arbitrary noun: "Sara's book" must not become "Sara is book".
final _contractionIs = RegExp(
  r"\b(he|she|it|that|there|what|who|where|how|here)'s\b",
  caseSensitive: false,
);
final _contractionAre = RegExp(r"\b(you|we|they)'re\b", caseSensitive: false);
final _contractionAm = RegExp(r"\bi'm\b", caseSensitive: false);
final _contractionNot = RegExp(r"n't\b", caseSensitive: false);
final _contractionWill = RegExp(r"'ll\b", caseSensitive: false);
final _contractionHave = RegExp(r"'ve\b", caseSensitive: false);

String _normalize(String text) {
  var result = text.trim().toLowerCase().replaceAll(_curlyApostrophes, "'");
  result = result.replaceAllMapped(_contractionIs, (m) => '${m[1]} is');
  result = result.replaceAllMapped(_contractionAre, (m) => '${m[1]} are');
  result = result.replaceAll(_contractionAm, 'i am');
  result = result.replaceAll(_contractionNot, ' not');
  result = result.replaceAll(_contractionWill, ' will');
  result = result.replaceAll(_contractionHave, ' have');
  // Punctuation anywhere in the sentence, not just at the end — a spoken
  // or typed answer commonly drops the internal full stop between two
  // clauses ("This is Sara. She's my friend." vs "This is Sara she's my
  // friend") without changing the meaning.
  result = result.replaceAll(_sentencePunctuation, ' ');
  result = result.replaceAll(_whitespaceRun, ' ').trim();
  return result;
}

final _letterSpellingPattern = RegExp(r'^[A-Za-z](-[A-Za-z])+$');

bool _isLetterSpellingAnswer(String text) =>
    _letterSpellingPattern.hasMatch(text.trim());

final _nonLetters = RegExp('[^a-z]');

/// [text] reduced to its lowercase Latin letters, dropping case, spacing,
/// and punctuation — e.g. "Ali", "a l i", and "A-L-I" all normalize to
/// "ali".
///
/// Returns an **empty string** for text with no Latin letters at all (an
/// Arabic name like "علي", digits, emoji). Callers that compare against a
/// learner- or content-supplied reference must check the *normalized* form
/// for emptiness, not the raw string: a non-Latin reference is non-empty raw
/// but unusable here, and comparing it would fail every answer forever. See
/// the `letterSequence` evaluator in
/// lib/features/activity_engine/domain/evaluation/evaluator.dart.
String lettersOnly(String text) =>
    text.toLowerCase().replaceAll(_nonLetters, '');

/// Whether [a] and [b] contain the same sequence of letters, ignoring case,
/// spacing, and punctuation — e.g. "Ali", "a l i", and "A-L-I" all match.
/// Shared by [answersMatch]'s letter-spelling case and the `letterSequence`
/// evaluator (see lib/features/activity_engine/domain/evaluation).
bool lettersOnlyMatch(String a, String b) => lettersOnly(a) == lettersOnly(b);
