import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';

Map<String, dynamic> _lexicon(List<Object> examples) => {
  'id': 'A2.LEX.STAY_V01',
  'headword': 'stay',
  'partOfSpeech': 'verb',
  'arabic': 'يقيم',
  'cefr': 'A2',
  'receptive': true,
  'productive': true,
  'meaning': 'stay',
  'examples': examples,
  'introducedIn': 'A2-U1-L2',
  'recycledIn': <String>[],
};

void main() {
  test("A1's examples are English sentences", () {
    final item = LexiconItem.fromJson(_lexicon(['I have one brother.']));
    expect(item.examples.single.en, 'I have one brother.');
    expect(item.examples.single.ar, isNull);
  });

  test("A2's examples carry their Arabic", () {
    final item = LexiconItem.fromJson(
      _lexicon([
        {'en': 'We are staying near the centre.', 'ar': 'نقيم قرب المركز.'},
      ]),
    );
    expect(item.examples.single.en, 'We are staying near the centre.');
    expect(item.examples.single.ar, 'نقيم قرب المركز.');
  });

  test('an empty Arabic example counts as none', () {
    final item = LexiconItem.fromJson(
      _lexicon([
        {'en': 'Stay here.', 'ar': ''},
      ]),
    );
    expect(item.examples.single.ar, isNull);
  });
}
