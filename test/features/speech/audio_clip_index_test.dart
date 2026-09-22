import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';

void main() {
  // Shared with tool/audio/tests/test_textkey.py — change both or neither.
  const vectors = {
    'My name is {name}.': '4a712aa44408d872',
    '  My   name is {name}.\n': '4a712aa44408d872',
    'I’m Omar.': 'fe69d774cfd057ee',
    "I'm Omar.": 'fe69d774cfd057ee',
    'Good morning.': '5c3e9f7ad0c9c2b8',
    "Hello! I'm Maya. Nice to meet you.": 'a29bdc5852db5cbf',
  };

  test('text keys match the authoring tool', () {
    vectors.forEach((text, key) {
      expect(textKeyFor(text), key, reason: text);
    });
  });

  const manifestJson = '''
  {"schemaVersion": 1, "levelId": "a1", "contentVersion": "V1",
   "clips": {"4a712aa44408d872": {"_": "clips/aaaa.m4a"},
             "5c3e9f7ad0c9c2b8": {"Maya": "clips/bbbb.m4a", "Omar": "clips/cccc.m4a"}}}''';

  test('manifest paths are resolved against the asset directory', () {
    final m = AudioManifest.parse(
      manifestJson,
      assetDirectory: 'assets/audio/en/A1',
    );
    expect(m.levelId, 'a1');
    expect(m.contentVersion, 'V1');
    expect(
      m.clips['4a712aa44408d872']!['_'],
      'assets/audio/en/A1/clips/aaaa.m4a',
    );
  });

  test('lookup prefers the speaker, then the teacher, then anything', () {
    final index = AudioClipIndex.fromManifests([
      AudioManifest.parse(manifestJson, assetDirectory: 'assets/audio/en/A1'),
    ]);
    expect(index.clipCount, 3);
    expect(
      index.assetPathFor('My name is {name}.'),
      'assets/audio/en/A1/clips/aaaa.m4a',
    );
    expect(
      index.assetPathFor('  My name is {name}. '),
      'assets/audio/en/A1/clips/aaaa.m4a',
    );
    expect(
      index.assetPathFor('Good morning.', speaker: 'Omar'),
      'assets/audio/en/A1/clips/cccc.m4a',
    );
    expect(
      index.assetPathFor('Good morning.', speaker: 'Sara'),
      'assets/audio/en/A1/clips/bbbb.m4a',
    );
    expect(
      index.assetPathFor('Good morning.'),
      'assets/audio/en/A1/clips/bbbb.m4a',
    );
    expect(index.assetPathFor('Not there.'), isNull);
    expect(const AudioClipIndex.empty().assetPathFor('Good morning.'), isNull);
  });

  test('a malformed manifest is a FormatException, not a crash elsewhere', () {
    expect(
      () => AudioManifest.parse('{"clips": 3}', assetDirectory: 'x'),
      throwsFormatException,
    );
    expect(
      () => AudioManifest.parse('[]', assetDirectory: 'x'),
      throwsFormatException,
    );
    expect(
      () => AudioManifest.parse('not json', assetDirectory: 'x'),
      throwsFormatException,
    );
  });
}
