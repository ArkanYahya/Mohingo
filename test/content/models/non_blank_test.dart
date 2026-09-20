import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/non_blank.dart';

void main() {
  test('a non-blank string reads back unchanged', () {
    expect(nonBlank('hello'), 'hello');
  });

  test('null reads as null', () {
    expect(nonBlank(null), isNull);
  });

  test('an empty string reads as null', () {
    expect(nonBlank(''), isNull);
  });

  test('a whitespace-only string reads as null', () {
    expect(nonBlank('   '), isNull);
  });

  test('a non-String value reads as null', () {
    expect(nonBlank(42), isNull);
  });
}
