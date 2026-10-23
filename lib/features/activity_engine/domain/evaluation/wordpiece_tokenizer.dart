/// The uncased BERT WordPiece tokenizer the bundled MiniLM embedding model
/// was trained with (ADR 0013): lower-case, strip accents, split off
/// punctuation, then greedy longest-match sub-words with `##` continuations.
/// Pure Dart, deterministic, pinned to the reference implementation by the
/// vectors in `wordpiece_tokenizer_test.dart`.
class WordPieceTokenizer {
  WordPieceTokenizer._(this._vocab, this._unk, this._cls, this._sep);

  /// Parses a `vocab.txt` — one token per line, the line number is the id.
  factory WordPieceTokenizer.fromVocab(String vocabText) {
    final vocab = <String, int>{};
    var i = 0;
    for (final line in vocabText.split('\n')) {
      final token = line.endsWith('\r')
          ? line.substring(0, line.length - 1)
          : line;
      if (token.isEmpty && i == 0) continue;
      vocab.putIfAbsent(token, () => i);
      i++;
    }
    int idOf(String special) {
      final id = vocab[special];
      if (id == null) throw ArgumentError('vocabulary has no $special');
      return id;
    }

    return WordPieceTokenizer._(
      vocab,
      idOf('[UNK]'),
      idOf('[CLS]'),
      idOf('[SEP]'),
    );
  }

  final Map<String, int> _vocab;
  final int _unk;
  final int _cls;
  final int _sep;

  /// At most this many characters in one word before it is `[UNK]` whole,
  /// as the reference implementation does.
  static const int maxCharsPerWord = 100;

  /// `[CLS] … [SEP]`, truncated to [maxTokens] in total (the `[SEP]` kept).
  List<int> encode(String text, {int maxTokens = 256}) {
    final ids = <int>[_cls];
    for (final word in basicTokens(text)) {
      ids.addAll(_wordPiece(word));
    }
    if (ids.length > maxTokens - 1) ids.length = maxTokens - 1;
    ids.add(_sep);
    return ids;
  }

  List<int> _wordPiece(String word) {
    // Work on code points, not UTF-16 units, so a character outside the
    // Basic Multilingual Plane is never split into lone surrogates.
    final chars = word.runes.map(String.fromCharCode).toList();
    if (chars.length > maxCharsPerWord) return [_unk];
    final out = <int>[];
    var start = 0;
    while (start < chars.length) {
      var end = chars.length;
      int? found;
      while (start < end) {
        final piece = chars.sublist(start, end).join();
        final id = _vocab[start == 0 ? piece : '##$piece'];
        if (id != null) {
          found = id;
          break;
        }
        end--;
      }
      if (found == null) return [_unk];
      out.add(found);
      start = end;
    }
    return out;
  }

  /// BERT's basic tokenization: clean, lower-case, strip accents, and split
  /// on whitespace and around every punctuation character.
  static List<String> basicTokens(String text) {
    final cleaned = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0 || rune == 0xFFFD || _isControl(rune)) continue;
      cleaned.writeCharCode(_isWhitespace(rune) ? 0x20 : rune);
    }
    final lowered = _stripAccents(cleaned.toString().toLowerCase());
    final tokens = <String>[];
    for (final chunk in lowered.split(' ')) {
      if (chunk.isEmpty) continue;
      final current = StringBuffer();
      for (final rune in chunk.runes) {
        if (_isPunctuation(rune)) {
          if (current.isNotEmpty) {
            tokens.add(current.toString());
            current.clear();
          }
          tokens.add(String.fromCharCode(rune));
        } else {
          current.writeCharCode(rune);
        }
      }
      if (current.isNotEmpty) tokens.add(current.toString());
    }
    return tokens;
  }

  static bool _isWhitespace(int c) =>
      c == 0x20 ||
      c == 0x09 ||
      c == 0x0A ||
      c == 0x0D ||
      _spaceSeparator.hasMatch(String.fromCharCode(c));

  static bool _isControl(int c) =>
      (c < 0x20 && c != 0x09 && c != 0x0A && c != 0x0D) ||
      (c >= 0x7F && c < 0xA0) ||
      _format.hasMatch(String.fromCharCode(c));

  /// ASCII punctuation (every non-alphanumeric printable character, as BERT
  /// defines it) plus every Unicode punctuation character.
  static bool _isPunctuation(int c) =>
      (c >= 33 && c <= 47) ||
      (c >= 58 && c <= 64) ||
      (c >= 91 && c <= 96) ||
      (c >= 123 && c <= 126) ||
      _punctuation.hasMatch(String.fromCharCode(c));

  static final _punctuation = RegExp(r'\p{P}', unicode: true);
  static final _format = RegExp(r'\p{Cf}', unicode: true);
  static final _spaceSeparator = RegExp(r'\p{Zs}', unicode: true);

  /// The reference implementation decomposes to NFD and drops combining
  /// marks. Dart has no normaliser in its core library, so the Latin letters
  /// that English text can carry are mapped directly; anything else is kept.
  static String _stripAccents(String s) {
    final out = StringBuffer();
    for (final rune in s.runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue; // combining marks
      out.write(_accentMap[rune] ?? String.fromCharCode(rune));
    }
    return out.toString();
  }

  static const _accentMap = <int, String>{
    0xE0: 'a',
    0xE1: 'a',
    0xE2: 'a',
    0xE3: 'a',
    0xE4: 'a',
    0xE5: 'a',
    0xE7: 'c',
    0xE8: 'e',
    0xE9: 'e',
    0xEA: 'e',
    0xEB: 'e',
    0xEC: 'i',
    0xED: 'i',
    0xEE: 'i',
    0xEF: 'i',
    0xF1: 'n',
    0xF2: 'o',
    0xF3: 'o',
    0xF4: 'o',
    0xF5: 'o',
    0xF6: 'o',
    0xF9: 'u',
    0xFA: 'u',
    0xFB: 'u',
    0xFC: 'u',
    0xFD: 'y',
    0xFF: 'y',
    0x101: 'a',
    0x103: 'a',
    0x105: 'a',
    0x107: 'c',
    0x10D: 'c',
    0x10F: 'd',
    0x113: 'e',
    0x117: 'e',
    0x119: 'e',
    0x11B: 'e',
    0x11F: 'g',
    0x12B: 'i',
    0x131: 'i',
    0x142: 'l',
    0x144: 'n',
    0x148: 'n',
    0x14D: 'o',
    0x151: 'o',
    0x159: 'r',
    0x15B: 's',
    0x15F: 's',
    0x161: 's',
    0x163: 't',
    0x165: 't',
    0x16B: 'u',
    0x16F: 'u',
    0x171: 'u',
    0x17A: 'z',
    0x17C: 'z',
    0x17E: 'z',
  };
}
