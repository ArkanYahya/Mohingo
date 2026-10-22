import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/wordpiece_tokenizer.dart';

/// Vectors produced by the reference implementation (Hugging Face
/// `tokenizers`, from the model's own `tokenizer.json`) on 2026-10-22. The
/// Dart tokenizer must produce exactly these ids, or the embedding the app
/// computes is not the one the model was trained for.
const _vectors = <String, List<int>>{
  'Hello world': [101, 7592, 2088, 102],
  "This is Sara. She's my friend.": [
    101,
    2023,
    2003,
    7354,
    1012,
    2016,
    1005,
    1055,
    2026,
    2767,
    1012,
    102,
  ],
  "I'd like two cheese sandwiches, please — and a tea.": [
    101,
    1045,
    1005,
    1040,
    2066,
    2048,
    8808,
    22094,
    1010,
    3531,
    1517,
    1998,
    1037,
    5572,
    1012,
    102,
  ],
  "At 7:30 I get up. It's 18 degrees!": [
    101,
    2012,
    1021,
    1024,
    2382,
    1045,
    2131,
    2039,
    1012,
    2009,
    1005,
    1055,
    2324,
    5445,
    999,
    102,
  ],
  "Don't worry; it isn't mine.": [
    101,
    2123,
    1005,
    1056,
    4737,
    1025,
    2009,
    3475,
    1005,
    1056,
    3067,
    1012,
    102,
  ],
  'café naïve résumé': [101, 7668, 15743, 13746, 102],
  'Playing football with my friends on Saturdays is unforgettable.': [
    101,
    2652,
    2374,
    2007,
    2026,
    2814,
    2006,
    18860,
    2003,
    4895,
    29278,
    18150,
    10880,
    1012,
    102,
  ],
};

void main() {
  late WordPieceTokenizer tokenizer;

  setUpAll(() {
    tokenizer = WordPieceTokenizer.fromVocab(
      File('assets/models/all-MiniLM-L6-v2-vocab.txt').readAsStringSync(),
    );
  });

  test('matches the reference implementation on the pinned vectors', () {
    for (final entry in _vectors.entries) {
      expect(tokenizer.encode(entry.key), entry.value, reason: entry.key);
    }
  });

  test('basic tokenization lower-cases, strips accents and splits '
      'punctuation', () {
    expect(WordPieceTokenizer.basicTokens("  Café!  It's\tOK\n"), [
      'cafe',
      '!',
      'it',
      "'",
      's',
      'ok',
    ]);
  });

  test(
    'an unknown word becomes [UNK], and a word longer than the limit too',
    () {
      // A private-use character, and one outside the Basic Multilingual
      // Plane, neither of which the vocabulary has.
      final unk = tokenizer.encode('\u{E000}');
      expect(tokenizer.encode('\u{10348}'), [101, 100, 102]);
      expect(unk, [101, 100, 102]);
      final long = tokenizer.encode('a' * 101);
      expect(long, [101, 100, 102]);
    },
  );

  test('truncates to maxTokens, keeping [SEP] last', () {
    final ids = tokenizer.encode(
      'one two three four five six seven eight nine ten',
      maxTokens: 6,
    );
    expect(ids, hasLength(6));
    expect(ids.first, 101);
    expect(ids.last, 102);
  });

  test('is deterministic', () {
    const text = 'I usually work in the morning and cook in the evening.';
    expect(tokenizer.encode(text), tokenizer.encode(text));
  });
}
