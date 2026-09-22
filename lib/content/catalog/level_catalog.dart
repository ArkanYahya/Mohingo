/// Whether a CEFR level has real content in this build, per
/// docs/PRODUCT.md's "A2-C2 must appear in the levels interface with a
/// clear Coming Soon state — they must not be selectable as if content
/// exists" rule.
///
/// [preview] sits between the other two: the level's content exists and
/// loads, so a learner can see what it covers, but its lessons don't open
/// until it is released (and a development build can open it — see
/// `applyPreviewOverrides`). [comingSoon] has no content at all.
enum LevelAvailability { available, preview, comingSoon }

/// The level every learner starts in, and the one the app cannot run
/// without — the router's content gate waits for this one alone, so a
/// later level failing to load never blocks the app.
const kBaseLevelId = 'a1';

/// One row of the app-owned, level-agnostic content catalogue.
///
/// Deliberately **not** derived from any curriculum bundle (a bundle only
/// ever describes one level) — this is what makes adding a real A2 bundle
/// later purely additive: one new [LevelCatalogEntry] + one new asset file,
/// zero changes to A1 code. See docs/ARCHITECTURE.md's content-loading
/// strategy.
class LevelCatalogEntry {
  const LevelCatalogEntry({
    required this.levelId,
    required this.cefrCode,
    required this.availability,
    this.bundleAssetPath,
    this.prerequisiteLevelId,
    this.audioManifestAssetPath,
  });

  /// Lowercase catalogue key (e.g. `"a1"`), used as the route path segment
  /// and the [courseBundleLoaderProvider]/[courseContentProvider] family key.
  final String levelId;

  /// The CEFR code as displayed (e.g. `"A1"`).
  final String cefrCode;
  final LevelAvailability availability;

  /// Set when [availability] is [LevelAvailability.available] or
  /// [LevelAvailability.preview] — both have content to load. Null for
  /// [LevelAvailability.comingSoon].
  final String? bundleAssetPath;

  /// The level this one builds on (A2 builds on A1), or null. Its content
  /// loads first, and this level's lessons may reference its grammar,
  /// words and phrases by id — shown to learners as "From A1". App-owned,
  /// like the rest of this table: bundles never declare it.
  final String? prerequisiteLevelId;

  /// The manifest of the level's bundled speech clips (ADR 0008,
  /// docs/DATA_MODEL.md), or null while a level ships none — its text then
  /// falls back to the device engine. A released level must have one; the
  /// gate in `test/content/levels/level_audio_test.dart` says so.
  final String? audioManifestAssetPath;
}

/// The full CEFR level catalogue for v1: A1 and A2 available, B1-C2 Coming
/// Soon. A2 was a preview until its content was authored and its gates
/// passed; [LevelAvailability.preview] is still the state a level sits in
/// while that is true of it. See docs/ROADMAP.md.
const kLevelCatalog = <LevelCatalogEntry>[
  LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'assets/content/en/A1/a1-course-bundle.json',
    audioManifestAssetPath: 'assets/audio/en/A1/manifest.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.available,
    bundleAssetPath: 'assets/content/en/A2/a2-course-bundle.json',
    prerequisiteLevelId: 'a1',
    audioManifestAssetPath: 'assets/audio/en/A2/manifest.json',
  ),
  LevelCatalogEntry(
    levelId: 'b1',
    cefrCode: 'B1',
    availability: LevelAvailability.comingSoon,
  ),
  LevelCatalogEntry(
    levelId: 'b2',
    cefrCode: 'B2',
    availability: LevelAvailability.comingSoon,
  ),
  LevelCatalogEntry(
    levelId: 'c1',
    cefrCode: 'C1',
    availability: LevelAvailability.comingSoon,
  ),
  LevelCatalogEntry(
    levelId: 'c2',
    cefrCode: 'C2',
    availability: LevelAvailability.comingSoon,
  ),
];

LevelCatalogEntry? levelCatalogEntry(String levelId) =>
    levelCatalogEntryIn(kLevelCatalog, levelId);

/// [levelCatalogEntry] over any catalogue — the app reads the catalogue
/// through `levelCatalogProvider`, which tests override.
LevelCatalogEntry? levelCatalogEntryIn(
  List<LevelCatalogEntry> catalog,
  String levelId,
) {
  for (final entry in catalog) {
    if (entry.levelId == levelId) return entry;
  }
  return null;
}

/// The level that builds on [levelId] — the one a learner who finishes it
/// moves into next. Null when nothing builds on it: the last level with
/// content, or a level no entry names as its prerequisite.
///
/// Structural only. Whether that level is actually open to this learner is
/// a separate question — see `levelAccessFor`.
LevelCatalogEntry? nextLevelEntryIn(
  List<LevelCatalogEntry> catalog,
  String levelId,
) {
  for (final entry in catalog) {
    // A level is never its own next level, however the catalogue is edited.
    if (entry.levelId == levelId) continue;
    if (entry.prerequisiteLevelId == levelId) return entry;
  }
  return null;
}

/// [catalog] with every level in [openedLevelIds] promoted from
/// [LevelAvailability.preview] to [LevelAvailability.available] — how a
/// development build opens a level that isn't released yet. A level with no
/// bundle can't be promoted; a level that is already available is
/// unaffected. Returns [catalog] itself when there is nothing to promote.
List<LevelCatalogEntry> applyPreviewOverrides(
  List<LevelCatalogEntry> catalog,
  Set<String> openedLevelIds,
) {
  if (openedLevelIds.isEmpty) return catalog;
  return [
    for (final entry in catalog)
      if (entry.availability == LevelAvailability.preview &&
          entry.bundleAssetPath != null &&
          openedLevelIds.contains(entry.levelId))
        LevelCatalogEntry(
          levelId: entry.levelId,
          cefrCode: entry.cefrCode,
          availability: LevelAvailability.available,
          bundleAssetPath: entry.bundleAssetPath,
          prerequisiteLevelId: entry.prerequisiteLevelId,
          audioManifestAssetPath: entry.audioManifestAssetPath,
        )
      else
        entry,
  ];
}
