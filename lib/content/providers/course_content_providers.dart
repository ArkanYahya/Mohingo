import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../catalog/level_catalog.dart';
import '../index/course_content_index.dart';
import '../models/course_bundle.dart';
import '../parsing/course_bundle_parser.dart';
import 'bundle_asset_loader.dart';

part 'course_content_providers.g.dart';

/// The level catalogue ([kLevelCatalog]); overridden in tests.
@Riverpod(keepAlive: true)
List<LevelCatalogEntry> levelCatalog(Ref ref) => kLevelCatalog;

/// Reads bundle assets; overridden in tests.
@Riverpod(keepAlive: true)
BundleAssetLoader bundleAssetLoader(Ref ref) => const RootBundleAssetLoader();

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
/// — see docs/ARCHITECTURE.md's content-loading strategy.
///
/// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
/// level's index and is built with it attached, so its lessons can
/// reference the earlier level's grammar, words and phrases.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check the catalogue before invoking this
/// provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> courseContent(Ref ref, String levelId) async {
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null || entry.availability != LevelAvailability.available) {
    throw StateError('Level "$levelId" has no content bundle to load');
  }
  final loader = ref.watch(bundleAssetLoaderProvider);
  final prerequisiteId = entry.prerequisiteLevelId;
  final prerequisiteFuture = prerequisiteId == null
      ? null
      : ref.watch(courseContentProvider(prerequisiteId).future);

  final rawJson = await loader.load(entry.bundleAssetPath!);
  if (prerequisiteFuture == null) {
    return Isolate.run(
      () => CourseContentIndex.build(CourseBundleParser.parse(rawJson)),
    );
  }
  final prerequisite = await prerequisiteFuture;
  final CourseBundle bundle = await Isolate.run(
    () => CourseBundleParser.parse(rawJson),
  );
  return CourseContentIndex.build(bundle, prerequisite: prerequisite);
}
