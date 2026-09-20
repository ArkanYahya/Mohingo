import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/providers/bundle_asset_loader.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/progress/domain/level_access.dart';
import 'package:mohingo/features/progress/providers/level_providers.dart';

import '../../../content/fixtures/minimal_bundle.dart';

class _FakeLoader implements BundleAssetLoader {
  _FakeLoader(this.assets);
  final Map<String, String> assets;
  @override
  Future<String> load(String assetPath) async => assets[assetPath]!;
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
];

ProviderContainer _container(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      levelCatalogProvider.overrideWithValue(_catalog),
      bundleAssetLoaderProvider.overrideWithValue(
        _FakeLoader({
          'a1.json': jsonEncode(minimalBundleJson(level: 'A1')),
          'a2.json': jsonEncode(minimalBundleJson(level: 'A2')),
        }),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a new learner is in the base level', () async {
    final container = _container(db);
    expect(await container.read(currentLevelIdProvider.future), 'a1');
  });

  test(
    'selecting a level enrols the learner in it and makes it current',
    () async {
      final container = _container(db);
      await container
          .read(levelSelectionControllerProvider.notifier)
          .select('a2');

      expect(await container.read(currentLevelIdProvider.future), 'a2');
    },
  );

  test('a level that builds on an unfinished one is locked until it is '
      'opened', () async {
    final container = _container(db);
    // levelAccessProvider is auto-disposing: hold a listener so reading its
    // future twice doesn't race its own disposal between reads.
    final subscription = container.listen(levelAccessProvider('a2'), (_, _) {});
    addTearDown(subscription.close);

    expect(
      await container.read(levelAccessProvider('a2').future),
      LevelAccess.lockedNeedsPrerequisite,
    );

    await container
        .read(levelSelectionControllerProvider.notifier)
        .unlock('a2');

    expect(
      await container.read(levelAccessProvider('a2').future),
      LevelAccess.open,
    );
  });
}
