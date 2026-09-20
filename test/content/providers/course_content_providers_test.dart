import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/providers/bundle_asset_loader.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';

import '../fixtures/minimal_bundle.dart';

class _FakeLoader implements BundleAssetLoader {
  _FakeLoader(this.assets);

  final Map<String, String> assets;
  final loaded = <String>[];

  @override
  Future<String> load(String assetPath) async {
    loaded.add(assetPath);
    return assets[assetPath]!;
  }
}

const _catalog = [
  LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a1.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a2.json',
    prerequisiteLevelId: 'a1',
  ),
  LevelCatalogEntry(
    levelId: 'b1',
    cefrCode: 'B1',
    availability: LevelAvailability.comingSoon,
  ),
];

ProviderContainer _container(_FakeLoader loader) {
  final container = ProviderContainer(
    overrides: [
      levelCatalogProvider.overrideWithValue(_catalog),
      bundleAssetLoaderProvider.overrideWithValue(loader),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

_FakeLoader _loader() => _FakeLoader({
  'a1.json': jsonEncode(
    minimalBundleJson(level: 'A1', grammar: [grammarRecord('A1.G.BE.I_AM')]),
  ),
  'a2.json': jsonEncode(
    minimalBundleJson(level: 'A2', lessonGrammar: ['A1.G.BE.I_AM']),
  ),
});

void main() {
  test('a level with a prerequisite has both bundles loaded, and the '
      "prerequisite's index attached so references to it resolve", () async {
    final loader = _loader();
    final container = _container(loader);

    final a2 = await container.read(courseContentProvider('a2').future);
    final a1 = await container.read(courseContentProvider('a1').future);

    expect(a2.prerequisite, same(a1));
    expect(a2.resolveGrammar('A1.G.BE.I_AM'), isNotNull);
    expect(loader.loaded, containsAll(['a1.json', 'a2.json']));
  });

  test('a level without a prerequisite has none', () async {
    final container = _container(_loader());
    final a1 = await container.read(courseContentProvider('a1').future);
    expect(a1.prerequisite, isNull);
  });

  test('a level with no content fails with a StateError', () async {
    final container = _container(_loader());
    await expectLater(
      container.read(courseContentProvider('b1').future),
      throwsStateError,
    );
  });

  test('an item opens in the level its id belongs to', () async {
    final container = _container(_loader());

    final forUnit = await container.read(
      contentIndexForIdProvider('A2-U1').future,
    );
    final forGrammar = await container.read(
      contentIndexForIdProvider('A1.G.BE.I_AM').future,
    );

    expect(
      forUnit,
      same(await container.read(courseContentProvider('a2').future)),
    );
    expect(
      forGrammar,
      same(await container.read(courseContentProvider('a1').future)),
    );
  });

  test('an id with no level prefix fails with a StateError', () async {
    final container = _container(_loader());
    await expectLater(
      container.read(contentIndexForIdProvider('TEST-U1').future),
      throwsStateError,
    );
  });
}
