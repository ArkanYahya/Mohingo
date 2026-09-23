import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/spoken_numbers.dart';

void main() {
  group('spokenNumberIn', () {
    test('reads digits, as before', () {
      expect(spokenNumberIn("I'm 25."), 25);
      expect(spokenNumberIn('I am 25 years old'), 25);
      expect(spokenNumberIn('3.5'), 3.5);
    });

    test('reads the words a recogniser returns for a spoken number', () {
      expect(spokenNumberIn("I'm twenty-five."), 25);
      expect(spokenNumberIn('I am twenty five years old'), 25);
      expect(spokenNumberIn('eighteen'), 18);
      expect(spokenNumberIn('I am forty.'), 40);
      expect(spokenNumberIn('one hundred and twenty'), 120);
      expect(spokenNumberIn('a hundred'), 100);
      expect(spokenNumberIn('two thousand and six'), 2006);
      expect(spokenNumberIn('It costs twelve dollars'), 12);
    });

    test('takes the first number, whichever notation comes first', () {
      expect(spokenNumberIn('twenty, not 30'), 20);
      expect(spokenNumberIn('30, not twenty'), 30);
    });

    test('finds no number in text without one', () {
      expect(spokenNumberIn('I am a student.'), isNull);
      expect(spokenNumberIn('and then'), isNull);
      expect(spokenNumberIn('a friend'), isNull);
      expect(spokenNumberIn(''), isNull);
    });
  });

  group('numberWords', () {
    test('writes a number the way it is spoken', () {
      expect(numberWords(0), 'zero');
      expect(numberWords(7), 'seven');
      expect(numberWords(15), 'fifteen');
      expect(numberWords(20), 'twenty');
      expect(numberWords(25), 'twenty five');
      expect(numberWords(100), 'one hundred');
      expect(numberWords(120), 'one hundred and twenty');
      expect(numberWords(2006), 'two thousand six');
    });

    test('round-trips through spokenNumberIn', () {
      for (final n in [0, 1, 9, 10, 11, 19, 20, 21, 99, 100, 101, 999, 1000]) {
        expect(spokenNumberIn(numberWords(n)), n, reason: '$n');
      }
    });

    test('leaves what it does not speak as digits', () {
      expect(numberWords(-3), '-3');
      expect(numberWords(10000), '10000');
    });
  });
}
