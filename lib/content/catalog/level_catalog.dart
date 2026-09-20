/// Whether a CEFR level has real content in this build, per
/// docs/PRODUCT.md's "A2-C2 must appear in the levels interface with a
/// clear Coming Soon state — they must not be selectable as if content
/// exists" rule.
enum LevelAvailability { available, comingSoon }

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
  });

  /// Lowercase catalogue key (e.g. `"a1"`), used as the route path segment
  /// and the [courseBundleLoaderProvider]/[courseContentProvider] family key.
  final String levelId;

  /// The CEFR code as displayed (e.g. `"A1"`).
  final String cefrCode;
  final LevelAvailability availability;

  /// Set only when [availability] is [LevelAvailability.available].
  final String? bundleAssetPath;

  /// The level this one builds on (A2 builds on A1), or null. Its content
  /// loads first, and this level's lessons may reference its grammar,
  /// words and phrases by id — shown to learners as "From A1". App-owned,
  /// like the rest of this table: bundles never declare it.
  final String? prerequisiteLevelId;
}

/// The full CEFR level catalogue for v1: A1 available, A2-C2 Coming Soon.
/// See docs/ROADMAP.md.
const kLevelCatalog = <LevelCatalogEntry>[
  LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'assets/content/en/A1/a1-course-bundle.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.comingSoon,
    prerequisiteLevelId: 'a1',
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
