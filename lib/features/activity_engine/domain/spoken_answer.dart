import '../../../content/models/activity.dart';
import 'spoken_numbers.dart';

/// An answer that came from the speech recogniser rather than the
/// learner's fingers, and what the grader forgives because of it.
///
/// A transcript's spelling is the recogniser's, not the learner's: it
/// writes "Sarah" for Sara, "two" for "to", "25" for "twenty-five". So a
/// spoken answer is graded by what was said — a word that sounds like one
/// of the task's [names] counts as that name, common homophones are one
/// word, and digits are their words — while a typed answer, whose
/// spelling is the learner's own, is graded as written. Nothing else is
/// loosened: sound alone cannot tell "bag" from "big" or "this" from
/// "these", which is exactly what A1 tests, so tolerance by sound is kept
/// to names. See ADR 0009.
class SpokenAnswer {
  const SpokenAnswer({this.names = const {}});

  /// The task's proper names, lower-case — see [namesInTask].
  final Set<String> names;
}

final _word = RegExp(r"[A-Za-z][A-Za-z']*");
final _sentenceEnd = RegExp(r'[.!?]\s*["“‘(]*$');

/// The proper names a task itself uses: every word it capitalises other
/// than at the start of a sentence, across its prompt, model answers,
/// partner lines, partner label, transcript and source card. "Introduce
/// Sara as your friend." names Sara; "Say: Noor is Sami's daughter" names
/// Noor and Sami. Lower-case, possessive stripped. A capitalised common
/// word ("English", "Saturday") comes along harmlessly: a transcript word
/// that sounds like it is it.
Set<String> namesInTask(Activity activity) {
  final texts = <String?>[
    activity.prompt,
    if (activity is SpeakActivity) ...[
      ...activity.accepted,
      ...activity.partnerTurns,
      activity.partnerSpeaker,
    ],
    if (activity is WriteActivity) ...activity.accepted,
    activity.raw['audioTranscript'] as String?,
    activity.raw['sourceCard'] as String?,
  ];
  final names = <String>{};
  for (final text in texts) {
    if (text == null) continue;
    for (final match in _word.allMatches(text)) {
      final word = match.group(0)!;
      final first = word[0];
      if (first.toUpperCase() != first || first.toLowerCase() == first) {
        continue; // not capitalised (or not a letter with case)
      }
      final before = text.substring(0, match.start).trimRight();
      if (before.isEmpty || _sentenceEnd.hasMatch(before)) continue;
      // "Sami's" names Sami; "I'm" and "I" name nobody.
      final base = word.toLowerCase().split("'").first;
      if (base.length > 1) names.add(base);
    }
  }
  return names;
}

String _stem(String word) =>
    word.endsWith("'s") ? word.substring(0, word.length - 2) : word;

/// Whether [heard], a normalised transcript word, counts as [expected], a
/// normalised word of an accepted answer or a rubric keyword.
bool spokenWordsMatch(String expected, String heard, SpokenAnswer spoken) {
  if (expected == heard) return true;
  if (canonicalHomophone(expected) == canonicalHomophone(heard)) return true;
  final possessive = expected.endsWith("'s");
  if (possessive != heard.endsWith("'s")) return false;
  final name = _stem(expected);
  if (!spoken.names.contains(name)) return false;
  final other = _stem(heard);
  return other.isNotEmpty && phoneticKey(name) == phoneticKey(other);
}

/// [tokens] with every run of digits written as the words it is spoken
/// as, so "at 7" and "at seven" are the same tokens.
List<String> withNumbersAsWords(List<String> tokens) => [
  for (final t in tokens)
    if (RegExp(r'^\d{1,4}$').hasMatch(t))
      ...numberWords(int.parse(t)).split(' ')
    else
      t,
];

// Words a recogniser cannot tell apart by ear. Each group's first member
// is the spelling both sides are reduced to before comparing.
const _homophones = [
  ['to', 'two', 'too'],
  ['for', 'four'],
  ['there', 'their', "they're"],
  ['no', 'know'],
  ['right', 'write'],
  ['hour', 'our'],
  ['where', 'wear'],
  ['week', 'weak'],
  ['meet', 'meat'],
  ['one', 'won'],
  ['son', 'sun'],
  ['hi', 'high'],
  ['by', 'buy', 'bye'],
  ['see', 'sea'],
  ['here', 'hear'],
  ['i', 'eye'],
  ['new', 'knew'],
  ['eight', 'ate'],
  ['be', 'bee'],
  ['blue', 'blew'],
  ['break', 'brake'],
  ['flour', 'flower'],
  ['hole', 'whole'],
  ['night', 'knight'],
  ['mail', 'male'],
  ['pair', 'pear'],
  ['peace', 'piece'],
  ['plain', 'plane'],
  ['sale', 'sail'],
  ['some', 'sum'],
  ['tail', 'tale'],
  ['wait', 'weight'],
  ['weather', 'whether'],
  ['which', 'witch'],
  ['would', 'wood'],
  ['dear', 'deer'],
  ['hair', 'hare'],
  ['fair', 'fare'],
  ['sent', 'cent', 'scent'],
  ['made', 'maid'],
  ['rain', 'reign'],
  ['role', 'roll'],
  ['road', 'rode'],
  ['way', 'weigh'],
  ['its', "it's"],
  ['whose', "who's"],
  ['your', "you're"],
];

final Map<String, String> _canonical = {
  for (final group in _homophones)
    for (final word in group) word: group.first,
};

/// [word] reduced to the one spelling of its homophone group, or itself.
String canonicalHomophone(String word) => _canonical[word] ?? word;

final _vowels = RegExp('[AEIOUY]');
final _nonLetters = RegExp('[^A-Z]');

/// A key that is the same for words that sound the same: "sara" and
/// "sarah", "maya" and "maia", "omar" and "umar", "lina" and "leena".
///
/// Metaphone (Philips, 1990) trimmed to what names need: consonants are
/// reduced to their sound classes, vowels are dropped except at the start,
/// and Y is a vowel, since in a name it is one. Coarse by design — "bag"
/// and "big" share a key — which is why the grader applies it to names
/// only ([spokenWordsMatch]).
String phoneticKey(String word) {
  var w = word.toUpperCase().replaceAll(_nonLetters, '');
  if (w.isEmpty) return '';
  // Initial clusters whose first letter is silent, then WH- and X-.
  if (w.startsWith('KN') ||
      w.startsWith('GN') ||
      w.startsWith('PN') ||
      w.startsWith('WR') ||
      w.startsWith('AE')) {
    w = w.substring(1);
  } else if (w.startsWith('WH')) {
    w = 'W${w.substring(2)}';
  } else if (w.startsWith('X')) {
    w = 'S${w.substring(1)}';
  }
  final out = StringBuffer();
  bool isVowel(int i) => i >= 0 && i < w.length && _vowels.hasMatch(w[i]);
  String at(int i) => i >= 0 && i < w.length ? w[i] : '';
  for (var i = 0; i < w.length; i++) {
    final c = w[i];
    // A doubled letter reads once (C is the exception in Metaphone; no
    // name here needs it).
    if (i > 0 && c == w[i - 1] && c != 'C') continue;
    switch (c) {
      case 'A' || 'E' || 'I' || 'O' || 'U' || 'Y':
        if (i == 0) out.write('A');
      case 'B':
        // A final B after M is silent (lamb, dumb).
        if (!(i == w.length - 1 && at(i - 1) == 'M')) out.write('B');
      case 'C':
        if (at(i + 1) == 'I' && at(i + 2) == 'A') {
          out.write('X');
        } else if (at(i + 1) == 'H') {
          out.write(at(i - 1) == 'S' ? 'K' : 'X');
          i++;
        } else if ('IEY'.contains(at(i + 1))) {
          if (at(i - 1) != 'S') out.write('S');
        } else {
          out.write('K');
        }
      case 'D':
        if (at(i + 1) == 'G' && 'EIY'.contains(at(i + 2))) {
          out.write('J');
          i += 2;
        } else {
          out.write('T');
        }
      case 'G':
        if (at(i + 1) == 'H') {
          // GH before a vowel sounds (Ghada); otherwise it is silent or an
          // F, which no name here has, so it is dropped.
          if (isVowel(i + 2)) out.write('K');
          i++;
        } else if (at(i + 1) == 'N') {
          // GN at the end (sign) is silent.
          if (i + 2 < w.length) out.write('K');
        } else if ('IEY'.contains(at(i + 1)) && at(i - 1) != 'G') {
          out.write('J');
        } else {
          out.write('K');
        }
      case 'H':
        // Silent after a vowel with no vowel following, and after the
        // consonants that already absorbed it.
        if (isVowel(i + 1) && !'CSPTG'.contains(at(i - 1))) out.write('H');
      case 'K':
        if (at(i - 1) != 'C') out.write('K');
      case 'P':
        if (at(i + 1) == 'H') {
          out.write('F');
          i++;
        } else {
          out.write('P');
        }
      case 'Q':
        out.write('K');
      case 'S':
        if (at(i + 1) == 'H' ||
            (at(i + 1) == 'I' && 'AO'.contains(at(i + 2)))) {
          out.write('X');
          if (at(i + 1) == 'H') i++;
        } else {
          out.write('S');
        }
      case 'T':
        if (at(i + 1) == 'I' && 'AO'.contains(at(i + 2))) {
          out.write('X');
        } else if (at(i + 1) == 'H') {
          out.write('0');
          i++;
        } else if (!(at(i + 1) == 'C' && at(i + 2) == 'H')) {
          out.write('T');
        }
      case 'V':
        out.write('F');
      case 'W':
        if (isVowel(i + 1)) out.write('W');
      case 'X':
        out.write('KS');
      case 'Z':
        out.write('S');
      default:
        out.write(c); // F J L M N R
    }
  }
  return out.toString();
}
