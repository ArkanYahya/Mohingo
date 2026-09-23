/// Numbers as a speech recogniser, or a learner, may write them.
///
/// A recogniser returns "25" for one speaker and "twenty-five" for the
/// next; a typed answer may say "twenty five". [spokenNumberIn] finds the
/// first number in a text either way, so a numeric-range rubric grades the
/// value, not the notation; [numberWords] writes digits the way the words
/// are spoken, so a transcript's "at 7" and a rubric's "at seven" compare
/// equal. English only, up to the thousands — the range these levels use.
library;

const _units = {
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
};

const _tens = {
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

final _digits = RegExp(r'^\d+([.,]\d+)?$');
final _separators = RegExp(r'[\s\-]+');
final _stripped = RegExp(r"[^a-z0-9.,]");
final _edgePunctuation = RegExp(r'^[.,]+|[.,]+$');

/// The first number in [text], in digits ("25", "3.5") or in words
/// ("twenty-five", "a hundred and twenty", "eighteen"), or null when there
/// is none.
double? spokenNumberIn(String text) {
  final tokens = text
      .toLowerCase()
      .split(_separators)
      .map((t) => t.replaceAll(_stripped, '').replaceAll(_edgePunctuation, ''))
      .where((t) => t.isNotEmpty)
      .toList();
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (_digits.hasMatch(token)) {
      return double.tryParse(token.replaceAll(',', '.'));
    }
    final words = _numberWordsAt(tokens, i);
    if (words != null) return words.toDouble();
  }
  return null;
}

/// The value of the number in words starting at [start], or null if no
/// number word starts there. "a hundred", "one hundred and five",
/// "twenty five", "two thousand" all read; a stray "and" outside a
/// number does not start one.
int? _numberWordsAt(List<String> tokens, int start) {
  var total = 0;
  var current = 0;
  var started = false;
  var i = start;
  while (i < tokens.length) {
    final t = tokens[i];
    if (_units.containsKey(t)) {
      current += _units[t]!;
      started = true;
    } else if (_tens.containsKey(t)) {
      current += _tens[t]!;
      started = true;
    } else if (t == 'hundred') {
      // "a hundred" / "hundred" on its own is one hundred.
      if (!started && i > start) break;
      current = (current == 0 ? 1 : current) * 100;
      started = true;
    } else if (t == 'thousand') {
      if (!started && i > start) break;
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
      started = true;
    } else if (t == 'a' && !started && i + 1 < tokens.length) {
      // Only as the article of "a hundred" / "a thousand".
      final next = tokens[i + 1];
      if (next != 'hundred' && next != 'thousand') return null;
    } else if (t == 'and' && started) {
      // "one hundred and five".
    } else {
      break;
    }
    i++;
  }
  return started ? total + current : null;
}

/// [value] in words, the way it is spoken — "seven", "twenty five", "one
/// hundred and twenty". Numbers this content does not use (negative, over
/// 9999, fractional) come back as their digits.
String numberWords(int value) {
  if (value < 0 || value > 9999) return '$value';
  if (value < 20) {
    return _units.entries.firstWhere((e) => e.value == value).key;
  }
  if (value < 100) {
    final tens = _tens.entries.firstWhere((e) => e.value == value ~/ 10 * 10);
    final unit = value % 10;
    return unit == 0 ? tens.key : '${tens.key} ${numberWords(unit)}';
  }
  if (value < 1000) {
    final rest = value % 100;
    final hundreds = '${numberWords(value ~/ 100)} hundred';
    return rest == 0 ? hundreds : '$hundreds and ${numberWords(rest)}';
  }
  final rest = value % 1000;
  final thousands = '${numberWords(value ~/ 1000)} thousand';
  return rest == 0 ? thousands : '$thousands ${numberWords(rest)}';
}
