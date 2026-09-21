import 'dart:convert';

import '../../../content/models/course_bundle.dart';
import '../../../data/local/database.dart';

/// What changed between the content a learner's progress was recorded
/// against and the content now loaded.
///
/// Only *losses* count as something to tell a learner about. Content that
/// grows — a new activity, a new objective — is a normal update and must
/// never nag. [addedCanDoIds] is carried for one narrow purpose: a unit
/// whose required objectives changed has moved its own bar, which the
/// learner deserves to know even though nothing of theirs was lost.
class ContentDrift {
  const ContentDrift({
    required this.removedActivityIds,
    required this.removedCanDoIds,
    required this.addedCanDoIds,
  });

  final Set<String> removedActivityIds;
  final Set<String> removedCanDoIds;
  final Set<String> addedCanDoIds;

  bool get isEmpty =>
      removedActivityIds.isEmpty &&
      removedCanDoIds.isEmpty &&
      addedCanDoIds.isEmpty;
}

/// Every Can-Do objective id a bundle names, from all three places one can
/// appear: a lesson's list, an activity's tags, and a unit's mastery
/// requirement.
///
/// Both the recorder and the differ call this. If they ever read different
/// sets, every upgrade would report drift that never happened.
Set<String> canDoIdsOf(CourseBundle bundle) => {
  for (final unit in bundle.units) ...[
    ...unit.mastery.requiredObjectives,
    for (final lesson in unit.lessons) ...[
      ...lesson.canDo,
      for (final activity in lesson.activities) ...activity.canDo,
    ],
  ],
};

Set<String> _decode(String json) =>
    (jsonDecode(json) as List).cast<String>().toSet();

/// The id-level diff. Split from [contentDriftBetween] so it can be tested
/// without building a whole bundle.
ContentDrift contentDriftFromIds({
  required ContentVersion previous,
  required Set<String> currentActivityIds,
  required Set<String> currentCanDoIds,
}) {
  final wasActivities = _decode(previous.activityIdsJson);
  final wasCanDos = _decode(previous.canDoIdsJson);
  return ContentDrift(
    removedActivityIds: wasActivities.difference(currentActivityIds),
    removedCanDoIds: wasCanDos.difference(currentCanDoIds),
    addedCanDoIds: currentCanDoIds.difference(wasCanDos),
  );
}

ContentDrift contentDriftBetween({
  required ContentVersion previous,
  required CourseBundle current,
  required Set<String> currentActivityIds,
}) => contentDriftFromIds(
  previous: previous,
  currentActivityIds: currentActivityIds,
  currentCanDoIds: canDoIdsOf(current),
);

/// The units this drift actually affects for *this* learner.
///
/// A unit is stale when the learner has an answer recorded against an
/// activity that no longer exists (their evidence is stranded), or when the
/// unit's required objectives are not the ones it required when they worked
/// on it (the bar moved under them). A unit whose content changed in ways
/// the learner never touched is not stale: there is nothing to tell them.
///
/// An activity outside any unit — a capstone's — has no unit row to say
/// anything on, so losing one flags nothing here.
Set<String> staleUnitIds({
  required ContentDrift drift,
  required Set<String> attemptedActivityIds,
  required Map<String, String> unitIdByActivityId,
  required Map<String, Set<String>> requiredObjectivesByUnitId,
}) {
  final stale = <String>{};

  for (final activityId in drift.removedActivityIds) {
    if (!attemptedActivityIds.contains(activityId)) continue;
    final unitId = unitIdByActivityId[activityId];
    if (unitId != null) stale.add(unitId);
  }

  final movedObjectives = drift.removedCanDoIds.union(drift.addedCanDoIds);
  for (final entry in requiredObjectivesByUnitId.entries) {
    if (entry.value.any(movedObjectives.contains)) stale.add(entry.key);
  }

  return stale;
}
