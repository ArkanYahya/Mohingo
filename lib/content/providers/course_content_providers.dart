import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../catalog/content_level.dart';
import '../catalog/level_catalog.dart';
import '../index/course_content_index.dart';
import '../models/course_bundle.dart';
import '../parsing/course_bundle_parser.dart';
import 'bundle_asset_loader.dart';

part 'course_content_providers.g.dart';

/// Levels this build opens although they aren't released — set at build
/// time with `--dart-define=MOHINGO_PREVIEW_LEVELS=a2` so the product owner
/// can walk through a level's real lessons before it ships. Empty in a
/// release build.
const _previewLevelIds = String.fromEnvironment('MOHINGO_PREVIEW_LEVELS');

/// The level catalogue ([kLevelCatalog]), with any development-opened
/// preview levels promoted; overridden in tests.
@Riverpod(keepAlive: true)
List<LevelCatalogEntry> levelCatalog(Ref ref) => applyPreviewOverrides(
  kLevelCatalog,
  _previewLevelIds
      .split(',')
      .map((id) => id.trim().toLowerCase())
      .where((id) => id.isNotEmpty)
      .toSet(),
);

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
/// A level with no bundle ([LevelAvailability.comingSoon]) or an unknown
/// [levelId] fails fast with a [StateError] — callers should check the
/// catalogue before invoking this provider, not rely on it to report
/// unavailability. A [LevelAvailability.preview] level's bundle loads like
/// an available one's; it is the Learn tab, not this provider, that keeps
/// its lessons closed.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> courseContent(Ref ref, String levelId) async {
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null || entry.bundleAssetPath == null) {
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

/// The index of the level [contentId] belongs to — for a screen that opens
/// one unit, lesson, activity, word, phrase or grammar point, so it shows
/// the right level without being told it. See [levelIdOfContentId].
///
/// Kept alive: it only hands on the already kept-alive level index, and
/// callers that `read` it from a callback (the refinement drain) must not
/// see it disposed mid-load. Trade-off: every distinct content id ever
/// opened keeps its own live family element here for the rest of the app's
/// life — bounded by the bundles' total id count (~1,400 today), each
/// element tiny, so this doesn't grow without bound.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> contentIndexForId(Ref ref, String contentId) async {
  final levelId = levelIdOfContentId(contentId);
  if (levelId == null) {
    throw StateError('"$contentId" has no level prefix');
  }
  return ref.watch(courseContentProvider(levelId).future);
}
