import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../domain/placement_plan.dart';

/// Every released level, in catalogue order, split into the blocks one
/// placement attempt scans — and the same object the Tests tab reads a
/// stored result back through (`plan.locate(unitId)`), so a recommended
/// unit is always numbered against the level its id names.
///
/// A released level whose bundle fails to load is left out rather than
/// failing the whole test: the app's rule is that a later level failing to
/// load never blocks what already works (see
/// `courseContentProvider`'s doc comment and the router's content gate).
/// A level that isn't released is left out too — the test may not measure
/// content the learner can't open.
///
/// Kept alive: it only hands on already kept-alive level indexes, and it
/// is read from the Tests tab on every rebuild.
final placementPlanProvider = FutureProvider<PlacementPlan>((ref) async {
  final catalog = ref.watch(levelCatalogProvider);
  final levels = <PlacementLevel>[];
  for (final entry in catalog) {
    if (entry.availability != LevelAvailability.available) continue;
    if (entry.bundleAssetPath == null) continue;
    try {
      final index = await ref.watch(
        courseContentProvider(entry.levelId).future,
      );
      levels.add(
        PlacementLevel(
          levelId: entry.levelId,
          cefrCode: entry.cefrCode,
          units: index.bundle.units,
          mediaByKey: index.bundle.mediaSpecifications,
        ),
      );
    } catch (_) {
      // Skipped, not fatal — see the doc comment above.
      continue;
    }
  }
  if (levels.isEmpty) {
    throw StateError('No released level has content to place a learner in');
  }
  return PlacementPlan.across(levels);
});

/// Where a stored placement result points, resolved against the level its
/// unit id names — never against whichever level is on screen, which is
/// how an A1 result once rendered as "Unit 0" beside A2's units.
///
/// Null when the id names no released level (or there is no id at all, as
/// for a "level mastered" result).
PlacementUnitRef? placementUnitRefIn(PlacementPlan? plan, String? unitId) =>
    plan?.locate(unitId);
