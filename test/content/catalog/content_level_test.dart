import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/content_level.dart';

void main() {
  test('reads the level from unit, lesson and activity ids', () {
    expect(levelIdOfContentId('A1-U3'), 'a1');
    expect(levelIdOfContentId('A1-U3-L2'), 'a1');
    expect(levelIdOfContentId('A2-U1-L1-A01'), 'a2');
    expect(levelIdOfContentId('A1-FINAL-MISSION-A01'), 'a1');
    expect(levelIdOfContentId('A2-FA-LISTEN-01'), 'a2');
  });

  test('reads the level from grammar, word and phrase ids', () {
    expect(levelIdOfContentId('A1.G.BE.I_AM'), 'a1');
    expect(levelIdOfContentId('A1.LEX.PICTURE.N01'), 'a1');
    expect(levelIdOfContentId('A2.LEX.STAY_V01'), 'a2');
    expect(levelIdOfContentId('A2.CHUNK.ON_WEEKDAYS'), 'a2');
  });

  test('an id with no level prefix has no level', () {
    expect(levelIdOfContentId('TEST-U1'), isNull);
    expect(levelIdOfContentId('U1'), isNull);
    expect(levelIdOfContentId(''), isNull);
  });
}
