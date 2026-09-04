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
    return _lettersOnly(accepted) == _lettersOnly(given);
  }

  return false;
}

final _curlyApostrophes = RegExp('[‘’ʼ]');
final _terminalPunctuation = RegExp(r'[.!?,;:]+$');

String _normalize(String text) {
  var result = text.trim().toLowerCase().replaceAll(_curlyApostrophes, "'");
  result = result.replaceAll(_terminalPunctuation, '').trim();
  return result;
}

final _letterSpellingPattern = RegExp(r'^[A-Za-z](-[A-Za-z])+$');

bool _isLetterSpellingAnswer(String text) =>
    _letterSpellingPattern.hasMatch(text.trim());

final _nonLetters = RegExp('[^a-z]');

String _lettersOnly(String text) =>
    text.toLowerCase().replaceAll(_nonLetters, '');
