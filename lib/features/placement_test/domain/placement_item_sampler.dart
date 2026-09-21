import 'dart:math';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';

/// Samples placement-test items from a [Unit]'s existing `practice`-mode
/// activities — the bundle has no dedicated placement-item pool at all
/// (verified against the real content this session), so this is a
/// documented, deliberate default: never `mastery` (that's training
/// evidence, not a one-shot test item) and never `encounter` (first
/// exposure, not something a learner should be expected to already know).
///
/// Sampling is seeded per attempt ([seed]) so a retake draws a different
/// item order/subset rather than repeating the exact same items — see
/// `PlacementAttempts.itemSamplingSeed`.
abstract final class PlacementItemSampler {
  static const int maxReceptiveItemsPerUnit = 3;

  /// Up to [limit] listening/reading practice items from [unit] — the
  /// auto-gradable skills the classification scan relies on.
  ///
  /// [limit] is 1 for a block pass (one item per unit decides the block)
  /// and [maxReceptiveItemsPerUnit] when a failed block is opened up unit
  /// by unit. [exclude] holds the activity ids this attempt has already
  /// asked, so a unit's drill-down never repeats the item its block pass
  /// asked: the shuffle is seeded per unit, so excluding the first item
  /// simply hands back the next ones in the same order.
  static List<Activity> receptiveItemsForUnit(
    Unit unit, {
    required int seed,
    int limit = maxReceptiveItemsPerUnit,
    Set<String> exclude = const {},
  }) {
    final candidates = <Activity>[
      for (final lesson in unit.lessons)
        for (final activity in lesson.activities)
          if (activity.mode == ActivityMode.practice &&
              (activity.skill == Skill.listening ||
                  activity.skill == Skill.reading))
            activity,
    ];
    if (candidates.isEmpty) return const [];
    candidates.shuffle(Random(seed));
    return candidates
        .where((activity) => !exclude.contains(activity.id))
        .take(limit)
        .toList();
  }

  /// One `write`/`speak` item from [unit], for the productive
  /// supporting-evidence sample — null if the unit has none. Never affects
  /// [PlacementClassifier]'s outcome (no reliable auto-grader exists yet for
  /// free-response answers, see docs/TECH_STACK.md); recorded purely as
  /// additional per-skill evidence in the result breakdown.
  ///
  /// Unlike [receptiveItemsForUnit], this draws from `mastery`-mode content
  /// too, not `practice` only — verified against the real bundle: every
  /// unit except `A1-U0` has zero `practice`-mode write/speak activities at
  /// all (productive practice items simply aren't part of this curriculum's
  /// design outside the very first unit), so a practice-only restriction
  /// would silently skip this step for almost every placement outcome. This
  /// is still safe: what keeps a placement item out of real mastery
  /// evidence is the `sessionType='placement'` it's recorded under, not the
  /// source activity's own `mode` — see docs/DATA_MODEL.md.
  static Activity? productiveItemForUnit(Unit unit, {required int seed}) {
    final candidates = <Activity>[
      for (final lesson in unit.lessons)
        for (final activity in lesson.activities)
          if (activity is WriteActivity || activity is SpeakActivity) activity,
    ];
    if (candidates.isEmpty) return null;
    candidates.shuffle(Random(seed));
    return candidates.first;
  }
}
