import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/media_specification.dart';

/// One released level as the placement test sees it: its units in bundle
/// order, and the media its activities play. Media stays per level — the
/// two bundles' keys happen not to collide today, and one merged map would
/// silently pick a winner the day they do.
class PlacementLevel {
  const PlacementLevel({
    required this.levelId,
    required this.cefrCode,
    required this.units,
    this.mediaByKey = const {},
  });

  /// The catalogue key, e.g. `"a2"`.
  final String levelId;

  /// The code the copy names it by, e.g. `"A2"`.
  final String cefrCode;

  final List<Unit> units;
  final Map<String, MediaSpecification> mediaByKey;
}

/// A run of consecutive units of one level, passed or failed as a group
/// before any unit inside it is looked at on its own — see
/// [splitIntoPlacementBlocks].
class PlacementBlock {
  const PlacementBlock({required this.level, required this.units});

  final PlacementLevel level;
  final List<Unit> units;
}

/// Where one unit sits in the scan: which level it belongs to, its number
/// **within that level**, and its position in the whole scan.
///
/// The number is 1-based inside its own level and nowhere else: A1-U0 is
/// A1's Unit 1 and A2-U1 is A2's Unit 1. Resolving a unit id against
/// whichever level happens to be on screen is what once rendered "Unit 0"
/// on the Tests tab — always go through [PlacementPlan.locate].
class PlacementUnitRef {
  const PlacementUnitRef({
    required this.level,
    required this.unit,
    required this.number,
    required this.scanIndex,
  });

  final PlacementLevel level;
  final Unit unit;

  /// 1-based within [level], matching every other screen's unit numbering
  /// (`units.indexOf(unit) + 1`).
  final int number;

  /// Position among every scannable unit, levels in order — what seeds
  /// this unit's item sampling, so a unit draws the same items whether the
  /// scan reaches it in a block pass or a drill-down.
  final int scanIndex;

  String get levelId => level.levelId;
  String get cefrCode => level.cefrCode;

  /// The level's opening unit — "start this level from the beginning".
  bool get isFirstInLevel => number == 1;
}

/// The size of every block after a level's first — three units, per
/// Design 4 of docs/superpowers/specs/2026-09-19-a2-level-design.md.
const int kPlacementBlockSize = 3;

/// [units] split into blocks of [kPlacementBlockSize], counted back from
/// the end so the leftover joins the *first* block.
///
/// That is what keeps blocks on whole unit numbers for both shipped
/// levels: A1's 13 units (a starter unit plus U1–U12) become U0–U3,
/// U4–U6, U7–U9, U10–U12, and A2's 12 become U1–U3, U4–U6, U7–U9,
/// U10–U12.
List<List<Unit>> splitIntoPlacementBlocks(List<Unit> units) {
  if (units.isEmpty) return const [];
  final remainder = units.length % kPlacementBlockSize;
  final blocks = <List<Unit>>[];
  var start = 0;
  var end =
      (remainder == 0 ? kPlacementBlockSize : remainder + kPlacementBlockSize)
          .clamp(0, units.length);
  while (start < units.length) {
    blocks.add(units.sublist(start, end));
    start = end;
    end = (start + kPlacementBlockSize).clamp(0, units.length);
  }
  return blocks;
}

/// Everything one placement attempt may scan: every released level, in
/// catalogue order, split into blocks.
///
/// The plan is also how a result is read back — [locate] turns a
/// recommended unit id into its level and its number in that level, and
/// [topLevel] is the most a result may ever claim, since nothing above it
/// has content to have been measured.
class PlacementPlan {
  PlacementPlan._({
    required this.levels,
    required this.blocks,
    required this.unitsById,
    required this.unitsBeforeBlock,
    required this.totalUnits,
  });

  factory PlacementPlan.across(List<PlacementLevel> levels) {
    final blocks = <PlacementBlock>[];
    final byUnitId = <String, PlacementUnitRef>{};
    final unitsBeforeBlock = <int>[];
    var scanIndex = 0;
    var unitsSoFar = 0;
    for (final level in levels) {
      for (final (i, unit) in level.units.indexed) {
        byUnitId[unit.id] = PlacementUnitRef(
          level: level,
          unit: unit,
          number: i + 1,
          scanIndex: scanIndex + i,
        );
      }
      scanIndex += level.units.length;
      for (final units in splitIntoPlacementBlocks(level.units)) {
        blocks.add(PlacementBlock(level: level, units: units));
        unitsBeforeBlock.add(unitsSoFar);
        unitsSoFar += units.length;
      }
    }
    return PlacementPlan._(
      levels: levels,
      blocks: blocks,
      unitsById: byUnitId,
      unitsBeforeBlock: unitsBeforeBlock,
      totalUnits: unitsSoFar,
    );
  }

  final List<PlacementLevel> levels;
  final List<PlacementBlock> blocks;

  /// Every scannable unit, by id — [locate]'s index.
  final Map<String, PlacementUnitRef> unitsById;

  /// How many units every earlier block holds — the progress bar's offset
  /// into its one-segment-per-block track.
  final List<int> unitsBeforeBlock;

  final int totalUnits;

  /// The highest released level. A result never names anything above it:
  /// there is no content above it to have been measured.
  PlacementLevel get topLevel => levels.last;

  /// The level and unit number [unitId] names, or null when no released
  /// level holds it.
  PlacementUnitRef? locate(String? unitId) =>
      unitId == null ? null : unitsById[unitId];

  /// Units settled before block [blockIndex] — [totalUnits] once the scan
  /// has run off the end of the plan.
  int unitsBefore(int blockIndex) => blockIndex >= unitsBeforeBlock.length
      ? totalUnits
      : unitsBeforeBlock[blockIndex];
}
