import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/answer_matching.dart';

void main() {
  group('answersMatch', () {
    test('matches an identical answer', () {
      expect(answersMatch('Thanks.', 'Thanks.'), isTrue);
    });

    test('matches case-insensitively', () {
      expect(answersMatch('Thanks.', 'THANKS.'), isTrue);
    });

    test(
      'matches when the given answer omits harmless terminal punctuation',
      () {
        expect(answersMatch('Thanks.', 'thanks'), isTrue);
      },
    );

    test('matches when the accepted answer omits punctuation the given '
        'answer includes', () {
      expect(answersMatch('Thanks', 'thanks.'), isTrue);
    });

    test('matches across a curly-vs-straight apostrophe', () {
      expect(answersMatch("What's your name?", 'what’s your name?'), isTrue);
    });

    test('does not match an unrelated answer', () {
      expect(answersMatch('Thanks.', 'hello'), isFalse);
    });

    group('letter-spelling accepted answers', () {
      test('matches a hyphen-joined accepted answer against itself', () {
        expect(answersMatch('A-L-I', 'A-L-I'), isTrue);
      });

      test('matches space-separated spoken letters against a '
          'hyphen-joined accepted answer', () {
        expect(answersMatch('A-L-I', 'a l i'), isTrue);
      });

      test('matches letters typed with no separator at all', () {
        expect(answersMatch('A-L-I', 'ali'), isTrue);
      });

      test('does not match a different letter sequence', () {
        expect(answersMatch('A-L-I', 'a l e'), isFalse);
      });
    });

    test('a non-spelling accepted answer is not loosened by the '
        'letter-spelling rule', () {
      // "One coffee, please." must not match a version with every space
      // removed just because some accepted answer elsewhere happens to
      // look letter-spelled — the spelling rule only applies when the
      // *accepted* answer itself is a hyphen-joined single-letter
      // sequence, which this is not.
      expect(answersMatch('One coffee, please.', 'onecoffeeplease'), isFalse);
    });
  });

  group('lettersOnly', () {
    test('keeps only lowercase Latin letters', () {
      expect(lettersOnly('A-L-I'), 'ali');
      expect(lettersOnly('a l i'), 'ali');
      expect(lettersOnly('Ali!'), 'ali');
      expect(lettersOnly("O'Brien"), 'obrien');
    });

    test('returns an empty string for text with no Latin letters', () {
      // The load-bearing case: an Arabic name a learner saved in Settings
      // is non-empty raw but has nothing this comparison can use, so
      // callers must check the normalized form, not the raw string. See the
      // letterSequence evaluator.
      expect(lettersOnly('علي'), isEmpty);
      expect(lettersOnly('١٢٣'), isEmpty);
      expect(lettersOnly('   '), isEmpty);
      expect(lettersOnly(''), isEmpty);
    });

    test('drops non-Latin characters but keeps Latin ones alongside them', () {
      expect(lettersOnly('Ali علي'), 'ali');
    });
  });

  group('lettersOnlyMatch', () {
    test('matches the same letters across spacing, case and punctuation', () {
      expect(lettersOnlyMatch('Ali', 'a l i'), isTrue);
      expect(lettersOnlyMatch('A-L-I', 'ali'), isTrue);
      expect(lettersOnlyMatch('Ali', 'A.L.I.'), isTrue);
    });

    test('does not match a different letter sequence', () {
      expect(lettersOnlyMatch('Ali', 'ale'), isFalse);
    });

    test('two letterless strings match each other — which is exactly why '
        'callers must guard an empty normalized reference', () {
      expect(lettersOnlyMatch('علي', 'محمد'), isTrue);
      expect(lettersOnlyMatch('علي', 'ali'), isFalse);
    });
  });
}
