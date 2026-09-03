import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../catalog/level_catalog.dart';
import '../index/course_content_index.dart';
import '../models/course_bundle.dart';
import '../parsing/course_bundle_parser.dart';

part 'course_content_providers.g.dart';

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's ~1,200-leaf-record bundle is parsed
/// once, not per screen — see docs/ARCHITECTURE.md's content-loading
/// strategy.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check [levelCatalogEntry] before invoking
/// this provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> courseContent(Ref ref, String levelId) async {
  final entry = levelCatalogEntry(levelId);
  if (entry == null || entry.availability != LevelAvailability.available) {
    throw StateError('Level "$levelId" has no content bundle to load');
  }

  final rawJson = await rootBundle.loadString(entry.bundleAssetPath!);
  return Isolate.run(() {
    final CourseBundle bundle = CourseBundleParser.parse(rawJson);
    return CourseContentIndex.build(bundle);
  });
}
