import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';

void main() {
  test('all 6 CEFR levels appear in the catalogue', () {
    expect(kLevelCatalog.map((e) => e.levelId), [
      'a1',
      'a2',
      'b1',
      'b2',
      'c1',
      'c2',
    ]);
  });

  test('only A1 is available; A2-C2 are Coming Soon', () {
    final a1 = levelCatalogEntry('a1')!;
    expect(a1.availability, LevelAvailability.available);
    expect(a1.bundleAssetPath, isNotNull);

    for (final levelId in ['a2', 'b1', 'b2', 'c1', 'c2']) {
      final entry = levelCatalogEntry(levelId)!;
      expect(
        entry.availability,
        LevelAvailability.comingSoon,
        reason: '$levelId must not be selectable as if content exists',
      );
      expect(entry.bundleAssetPath, isNull);
    }
  });

  test('an unknown level id resolves to null, not a crash', () {
    expect(levelCatalogEntry('z9'), isNull);
  });
}
