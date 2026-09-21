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

  test('A1 and A2 are available; B1-C2 are Coming Soon', () {
    // A2 shipped as a preview from 2026-09-20 until its content was
    // written: the imported bundle had one-line conversations, no working
    // graders and no present perfect at all. It became available once all
    // twelve units and both capstones passed the content gates in
    // test/content/a2_*. Changing this expectation is deliberate — the
    // release rule in a2_masterable_test.dart is the other half of the
    // brake, and it checks the content rather than the catalogue.
    final a1 = levelCatalogEntry('a1')!;
    expect(a1.availability, LevelAvailability.available);
    expect(a1.bundleAssetPath, isNotNull);

    final a2 = levelCatalogEntry('a2')!;
    expect(a2.availability, LevelAvailability.available);
    expect(a2.bundleAssetPath, isNotNull);
    expect(a2.prerequisiteLevelId, 'a1');

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
      // A second preview level with a bundle, never named below — proves
      // the flag opens only the levels it names, not every preview level.
      LevelCatalogEntry(
        levelId: 'b2',
        cefrCode: 'B2',
        availability: LevelAvailability.preview,
        bundleAssetPath: 'b2.json',
      ),
      // A preview level with no bundle at all — proves the bundle guard
      // holds even when the level is explicitly named.
      LevelCatalogEntry(
        levelId: 'c1',
        cefrCode: 'C1',
        availability: LevelAvailability.preview,
      ),
    ];

    final opened = applyPreviewOverrides(catalog, {'a2'});
    expect(opened.map((e) => e.availability), [
      LevelAvailability.available,
      LevelAvailability.available,
      LevelAvailability.comingSoon,
      LevelAvailability.preview, // b2 has a bundle but wasn't named.
      LevelAvailability.preview,
    ]);
    // Everything else about the entry survives the override.
    expect(opened[1].bundleAssetPath, 'a2.json');
    expect(opened[1].prerequisiteLevelId, 'a1');

    // A level with no bundle can't be opened by the flag, even when named.
    expect(
      applyPreviewOverrides(catalog, {'b1'})[2].availability,
      LevelAvailability.comingSoon,
    );
    expect(
      applyPreviewOverrides(catalog, {'c1'})[4].availability,
      LevelAvailability.preview,
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
