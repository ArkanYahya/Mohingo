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

  test('only A1 is available; A2 is a preview; B1-C2 are Coming Soon', () {
    final a1 = levelCatalogEntry('a1')!;
    expect(a1.availability, LevelAvailability.available);
    expect(a1.bundleAssetPath, isNotNull);

    final a2 = levelCatalogEntry('a2')!;
    expect(a2.availability, LevelAvailability.preview);
    expect(a2.bundleAssetPath, isNotNull);

    for (final levelId in ['b1', 'b2', 'c1', 'c2']) {
      final entry = levelCatalogEntry(levelId)!;
      expect(
        entry.availability,
        LevelAvailability.comingSoon,
        reason: '$levelId must not be selectable as if content exists',
      );
      expect(entry.bundleAssetPath, isNull);
    }
  });

  test('a preview level is opened by the development flag, and everything '
      'else is left alone', () {
    const catalog = [
      LevelCatalogEntry(
        levelId: 'a1',
        cefrCode: 'A1',
        availability: LevelAvailability.available,
        bundleAssetPath: 'a1.json',
      ),
      LevelCatalogEntry(
        levelId: 'a2',
        cefrCode: 'A2',
        availability: LevelAvailability.preview,
        bundleAssetPath: 'a2.json',
        prerequisiteLevelId: 'a1',
      ),
      LevelCatalogEntry(
        levelId: 'b1',
        cefrCode: 'B1',
        availability: LevelAvailability.comingSoon,
      ),
    ];

    final opened = applyPreviewOverrides(catalog, {'a2'});
    expect(opened.map((e) => e.availability), [
      LevelAvailability.available,
      LevelAvailability.available,
      LevelAvailability.comingSoon,
    ]);
    // Everything else about the entry survives the override.
    expect(opened[1].bundleAssetPath, 'a2.json');
    expect(opened[1].prerequisiteLevelId, 'a1');

    // A level with no bundle can't be opened by the flag.
    expect(
      applyPreviewOverrides(catalog, {'b1'})[2].availability,
      LevelAvailability.comingSoon,
    );
    expect(applyPreviewOverrides(catalog, const {}), same(catalog));
  });

  test('an unknown level id resolves to null, not a crash', () {
    expect(levelCatalogEntry('z9'), isNull);
  });

  test('A2 builds on A1; A1 builds on nothing', () {
    expect(levelCatalogEntry('a1')!.prerequisiteLevelId, isNull);
    expect(levelCatalogEntry('a2')!.prerequisiteLevelId, 'a1');
  });

  test('levelCatalogEntryIn looks an entry up in any catalogue', () {
    const catalog = [
      LevelCatalogEntry(
        levelId: 'x1',
        cefrCode: 'X1',
        availability: LevelAvailability.available,
        bundleAssetPath: 'x1.json',
      ),
    ];
    expect(levelCatalogEntryIn(catalog, 'x1')!.bundleAssetPath, 'x1.json');
    expect(levelCatalogEntryIn(catalog, 'a1'), isNull);
  });
}
