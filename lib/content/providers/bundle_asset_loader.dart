import 'package:flutter/services.dart' show rootBundle;

/// Reads a curriculum bundle asset's raw JSON. The app uses
/// [RootBundleAssetLoader]; tests override `bundleAssetLoaderProvider`
/// with a fake so loading can be exercised without real assets.
abstract interface class BundleAssetLoader {
  Future<String> load(String assetPath);
}

class RootBundleAssetLoader implements BundleAssetLoader {
  const RootBundleAssetLoader();

  @override
  Future<String> load(String assetPath) => rootBundle.loadString(assetPath);
}
