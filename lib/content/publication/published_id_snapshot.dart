import '../models/activity.dart';
import '../models/course_bundle.dart';

/// What was published about one activity, and may never change.
///
/// `activity_attempts` rows store `activityId`, `mode` and `canDoId` as
/// bundle strings with no foreign key. They outlive the content. Change a
/// published mode and every stored attempt is re-interpreted; drop a
/// published objective and the evidence stops mapping to anything.
class PublishedActivity {
  const PublishedActivity({required this.mode, required this.canDo});

  final String mode;
  final Set<String> canDo;
}

/// The id surface one level has published, as committed under
/// `test/content/published/`.
class PublishedIdSnapshot {
  const PublishedIdSnapshot({
    required this.courseId,
    required this.contentVersion,
    required this.unitIds,
    required this.lessonIds,
    required this.activities,
    required this.canDoIds,
  });

  factory PublishedIdSnapshot.fromBundle(CourseBundle bundle) {
    final activities = <String, PublishedActivity>{};
    final canDoIds = <String>{};

    void record(Activity activity) {
      canDoIds.addAll(activity.canDo);
      activities[activity.id] = PublishedActivity(
        mode: activity.mode.name,
        canDo: activity.canDo.toSet(),
      );
    }

    for (final unit in bundle.units) {
      canDoIds.addAll(unit.mastery.requiredObjectives);
      for (final lesson in unit.lessons) {
        canDoIds.addAll(lesson.canDo);
        lesson.activities.forEach(record);
      }
    }
    // Capstone activities are published ids too: a learner has attempts
    // against them, and nothing else in this file would notice one going
    // missing.
    bundle.finalMission.activities.forEach(record);
    bundle.finalAssessment.allActivities.forEach(record);

    return PublishedIdSnapshot(
      courseId: bundle.course.id,
      contentVersion: bundle.contentVersion,
      unitIds: {for (final u in bundle.units) u.id},
      lessonIds: {
        for (final u in bundle.units)
          for (final l in u.lessons) l.id,
      },
      activities: activities,
      canDoIds: canDoIds,
    );
  }

  factory PublishedIdSnapshot.fromJson(Map<String, dynamic> json) =>
      PublishedIdSnapshot(
        courseId: json['courseId'] as String,
        contentVersion: json['contentVersion'] as String,
        unitIds: (json['unitIds'] as List).cast<String>().toSet(),
        lessonIds: (json['lessonIds'] as List).cast<String>().toSet(),
        activities: {
          for (final e in (json['activities'] as Map).entries)
            e.key as String: PublishedActivity(
              mode: (e.value as Map)['mode'] as String,
              canDo: ((e.value as Map)['canDo'] as List).cast<String>().toSet(),
            ),
        },
        canDoIds: (json['canDoIds'] as List).cast<String>().toSet(),
      );

  final String courseId;

  /// The bundle's `contentVersion` at the time this id surface was
  /// recorded. Kept so the script can refuse to record new ids under an
  /// unchanged version — see `tool/update_published_ids.dart`.
  final String contentVersion;

  final Set<String> unitIds;
  final Set<String> lessonIds;
  final Map<String, PublishedActivity> activities;
  final Set<String> canDoIds;

  /// Sorted on the way out so the committed file has a stable diff — a
  /// snapshot that reorders itself on every regeneration is a snapshot
  /// nobody reviews.
  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'contentVersion': contentVersion,
    'unitIds': unitIds.toList()..sort(),
    'lessonIds': lessonIds.toList()..sort(),
    'activities': {
      for (final id in activities.keys.toList()..sort())
        id: {
          'mode': activities[id]!.mode,
          'canDo': activities[id]!.canDo.toList()..sort(),
        },
    },
    'canDoIds': canDoIds.toList()..sort(),
  };
}

/// Whether the two snapshots publish different ids at all, in either
/// direction. Adding content counts: that is the case the version gate
/// exists for.
bool publishedIdsDiffer(PublishedIdSnapshot a, PublishedIdSnapshot b) {
  bool same(Set<String> x, Set<String> y) =>
      x.length == y.length && x.containsAll(y);
  return !same(a.unitIds, b.unitIds) ||
      !same(a.lessonIds, b.lessonIds) ||
      !same(a.canDoIds, b.canDoIds) ||
      !same(a.activities.keys.toSet(), b.activities.keys.toSet());
}

/// Every way [current] is an illegal successor to [published].
///
/// Legal: anything added. Illegal: an id that disappeared, a `mode` that
/// changed, an objective an activity no longer carries.
///
/// Returned as a list rather than thrown one at a time because a content
/// edit that breaks this usually breaks it in dozens of places at once,
/// and a gate that reports one offender per run is a gate people stop
/// running.
List<String> publicationViolations({
  required PublishedIdSnapshot published,
  required PublishedIdSnapshot current,
}) {
  final violations = <String>[];

  if (published.courseId != current.courseId) {
    violations.add(
      'course id changed from ${published.courseId} to ${current.courseId}; '
      'every stored attempt was recorded against the old one',
    );
  }

  void missing(String kind, Set<String> was, Set<String> now) {
    for (final id in (was.difference(now).toList()..sort())) {
      violations.add(
        '$kind $id was published and is gone; ids are permanent — if this '
        'content is retired, leave the id in place or give the replacement '
        'a new one',
      );
    }
  }

  missing('unit', published.unitIds, current.unitIds);
  missing('lesson', published.lessonIds, current.lessonIds);
  missing('objective', published.canDoIds, current.canDoIds);

  for (final id in (published.activities.keys.toList()..sort())) {
    final was = published.activities[id]!;
    final now = current.activities[id];
    if (now == null) {
      violations.add(
        'activity $id was published and is gone; learners have attempts '
        'recorded against it',
      );
      continue;
    }
    if (was.mode != now.mode) {
      violations.add(
        'activity $id was published as ${was.mode} and is now ${now.mode}; '
        'mode is frozen after publication — every stored attempt on it '
        'would be re-counted',
      );
    }
    final dropped = was.canDo.difference(now.canDo).toList()..sort();
    for (final objective in dropped) {
      violations.add(
        'activity $id no longer carries $objective; canDo is append-only '
        'after publication — stored evidence still names it',
      );
    }
  }

  return violations;
}

/// The snapshot to commit after adding content: everything published, plus
/// everything new, recorded under the bundle's current `contentVersion`.
///
/// Throws rather than laundering a removal, and throws rather than
/// recording new ids under an unchanged `contentVersion` — a content
/// change that keeps the old version string is invisible to stale
/// detection on every device, because the app treats an unchanged version
/// as "not an upgrade" and skips the diff entirely.
PublishedIdSnapshot mergeForPublication({
  required PublishedIdSnapshot published,
  required PublishedIdSnapshot current,
}) {
  final violations = publicationViolations(
    published: published,
    current: current,
  );
  if (violations.isNotEmpty) {
    throw StateError(
      'the bundle is not a legal successor to the published snapshot, so '
      'regenerating would erase what it is there to protect:\n'
      '${violations.join('\n')}',
    );
  }
  if (publishedIdsDiffer(published, current) &&
      published.contentVersion == current.contentVersion) {
    throw StateError(
      'the bundle publishes different ids but still declares '
      'contentVersion "${current.contentVersion}". A learner\'s device '
      'treats an unchanged contentVersion as "not an upgrade" and never '
      'diffs the content, so nothing would be flagged as stale for anyone. '
      'Bump contentVersion in the bundle, then run this again.',
    );
  }
  return PublishedIdSnapshot(
    courseId: current.courseId,
    contentVersion: current.contentVersion,
    unitIds: {...published.unitIds, ...current.unitIds},
    lessonIds: {...published.lessonIds, ...current.lessonIds},
    activities: {
      for (final id in {
        ...published.activities.keys,
        ...current.activities.keys,
      })
        id: current.activities[id] ?? published.activities[id]!,
    },
    canDoIds: {...published.canDoIds, ...current.canDoIds},
  );
}
