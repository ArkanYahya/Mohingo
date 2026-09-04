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
}
