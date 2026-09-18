import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/router/legacy_learn_redirect.dart';

void main() {
  test('a level address now lands on the Learn tab itself', () {
    expect(legacyLearnRedirect(Uri.parse('/learn/a1')), '/learn');
    expect(legacyLearnRedirect(Uri.parse('/learn/b2')), '/learn');
  });

  test('a unit under a level moves to /learn/unit/<id>', () {
    expect(
      legacyLearnRedirect(Uri.parse('/learn/a1/unit/A1-U3')),
      '/learn/unit/A1-U3',
    );
  });

  test('current addresses are left alone', () {
    expect(legacyLearnRedirect(Uri.parse('/learn')), isNull);
    expect(legacyLearnRedirect(Uri.parse('/learn/unit/A1-U3')), isNull);
    expect(legacyLearnRedirect(Uri.parse('/home')), isNull);
  });
}
