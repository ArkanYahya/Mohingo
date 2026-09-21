# Published Id Stability Guard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make "ids are permanent once published" a rule a test enforces, not a sentence in a document.

**Architecture:** A committed JSON snapshot per released level records every published unit, lesson and activity id, each activity's `mode`, and the Can-Do objectives it carries. A test compares the shipped bundle against that snapshot in both directions: the bundle may never lose an id, change a published `mode`, or drop a published `canDo` tag, and the snapshot may never fall behind the bundle. A small `tool/` script keeps the snapshot current, and it is additive by construction — it merges, never overwrites — so making the gate green by regenerating it is not a move that exists.

**Tech Stack:** Dart, `flutter_test`, `dart:io`, `dart:convert`. No new dependency.

**Spec:** No design doc — this plan is the design. The rule it enforces is stated in `docs/DATA_MODEL.md` ("ids are stable across content versions") and in `lib/data/local/tables/attempt_tables.dart:10`, and today nothing checks it.

## Global Constraints

- The app works fully offline. Nothing here ships in the app: the snapshot and the script are test-time and dev-time only.
- No new dependency. The script runs under `dart run`, not `build_runner`.
- This plan does not touch A2 content, and does not regenerate any bundle from `reference/a2-modular-course/`.
- It does not presume how content is delivered. Whether the next bundle arrives in an app update or over a network is an open product decision; this gate reads the bundle in `assets/` either way.

---

## Why this is worth building

`activity_attempts` stores `activityId`, `lessonId`, `mode` and `canDoId` as **bundle string ids** (`lib/data/local/tables/attempt_tables.dart:24,25,30,48`), with no foreign key to anything. The rows outlive the content they point at. The comment at `attempt_tables.dart:10` says changing an activity's `mode` after publication "corrupts prior mastery history", and that is the whole enforcement: a comment.

The three ways this breaks a learner, all currently possible in a single careless edit:

1. **An id is reused.** A learner's attempt on the old `A2-U3-L2-A07` is counted as evidence for a different activity that now wears that id.
2. **A published `mode` changes.** `MasteryAggregationService` counts mastery-mode evidence. Re-tag one activity from `practice` to `mastery` and every learner who ever answered it retroactively gains evidence they never earned; go the other way and they lose mastery they did earn.
3. **A published `canDo` tag is dropped.** The attempt rows still carry the old objective id. The unit's requirement now names an objective no stored evidence maps to, and a learner who had mastered the unit stops having mastered it.

**The policy, decided by the product owner:** after a level is published, **`canDo` is append-only and `mode` is frozen.** An activity may gain an objective; it may never lose one, and it may never change mode. Removing either means a new activity id.

## File structure

| File | Responsibility |
|---|---|
| `test/content/published/a1-published-ids.json` | **New, committed.** A1's published id surface. Data, never hand-edited except to record a deliberate removal. |
| `test/content/published/a2-published-ids.json` | **New, committed.** The same for A2. |
| `lib/content/publication/published_id_snapshot.dart` | **New.** The snapshot's shape and its two directions of comparison, as pure functions. Lives in `lib/` rather than `test/` so the script and the test share one implementation instead of two that drift. |
| `tool/update_published_ids.dart` | **New.** Merges what the bundle now has into the snapshot. Refuses to drop an id, change a mode, or drop a tag — so it cannot be used to silence the gate. |
| `test/content/published_id_stability_test.dart` | **New.** The gate. |
| `test/content/publication/published_id_snapshot_test.dart` | **New.** The comparison functions, as data. |
| `docs/CONVENTIONS.md`, `docs/DATA_MODEL.md` | **Modify.** State the policy and where it is enforced. |

---

### Task 1: The snapshot's shape and its comparisons

**Files:**
- Create: `lib/content/publication/published_id_snapshot.dart`
- Test: `test/content/publication/published_id_snapshot_test.dart`

**Interfaces:**
- Produces:
  - `class PublishedActivity { final String mode; final Set<String> canDo; }`
  - `class PublishedIdSnapshot { final String courseId; final Set<String> unitIds; final Set<String> lessonIds; final Map<String, PublishedActivity> activities; final Set<String> canDoIds; PublishedIdSnapshot.fromJson(Map<String, dynamic>); Map<String, dynamic> toJson(); PublishedIdSnapshot.fromBundle(CourseBundle); }`
  - `List<String> publicationViolations({required PublishedIdSnapshot published, required PublishedIdSnapshot current})` — a list of human-readable violations, empty when the bundle is a legal successor.
  - `PublishedIdSnapshot mergeForPublication({required PublishedIdSnapshot published, required PublishedIdSnapshot current})` — the additive merge; throws `StateError` listing every violation if `current` is not a legal successor.

**Why violations are a returned list rather than thrown one at a time:** a content edit that breaks this usually breaks it in dozens of places at once. A gate that reports the first offender makes the author re-run it dozens of times; one that reports all of them is fixed in a single pass. The A2 capstone gates already work this way (`a2_capstone_checks.dart`), so this matches the house style.

- [ ] **Step 1: Write the failing test**

```dart
// test/content/publication/published_id_snapshot_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

PublishedIdSnapshot _snap({
  Set<String> units = const {'U1'},
  Set<String> lessons = const {'U1-L1'},
  Map<String, PublishedActivity> activities = const {},
  Set<String> canDoIds = const {'X.LISTENING.1'},
}) => PublishedIdSnapshot(
  courseId: 'EN-A2-V1',
  unitIds: units,
  lessonIds: lessons,
  activities: activities,
  canDoIds: canDoIds,
);

const _a01 = 'U1-L1-A01';

void main() {
  test('an unchanged bundle is a legal successor', () {
    final published = _snap(
      activities: {
        _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
      },
    );
    expect(
      publicationViolations(published: published, current: published),
      isEmpty,
    );
  });

  test('added content is legal: a new unit, a new activity, a new tag', () {
    final published = _snap(
      activities: {
        _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
      },
    );
    final current = _snap(
      units: {'U1', 'U2'},
      lessons: {'U1-L1', 'U2-L1'},
      activities: {
        _a01: PublishedActivity(
          mode: 'mastery',
          canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
        ),
        'U2-L1-A01': PublishedActivity(mode: 'practice', canDo: {'X.R.1'}),
      },
      canDoIds: {'X.LISTENING.1', 'X.LISTENING.2', 'X.R.1'},
    );
    expect(
      publicationViolations(published: published, current: current),
      isEmpty,
    );
  });

  test('a removed activity id is a violation that names it', () {
    final published = _snap(
      activities: {
        _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
      },
    );
    final violations = publicationViolations(
      published: published,
      current: _snap(activities: const {}),
    );
    expect(violations, hasLength(1));
    expect(violations.single, contains(_a01));
  });

  test('a changed mode is a violation, and says both modes', () {
    final violations = publicationViolations(
      published: _snap(
        activities: {
          _a01: PublishedActivity(mode: 'practice', canDo: {'X.LISTENING.1'}),
        },
      ),
      current: _snap(
        activities: {
          _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
        },
      ),
    );
    expect(violations.single, allOf(contains('practice'), contains('mastery')));
  });

  test('a dropped canDo tag is a violation — canDo is append-only', () {
    final violations = publicationViolations(
      published: _snap(
        activities: {
          _a01: PublishedActivity(
            mode: 'mastery',
            canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
          ),
        },
      ),
      current: _snap(
        activities: {
          _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
        },
      ),
    );
    expect(violations.single, contains('X.LISTENING.2'));
  });

  test('a removed unit, lesson and objective are each reported, not just '
      'the first', () {
    final violations = publicationViolations(
      published: _snap(
        units: {'U1', 'U2'},
        lessons: {'U1-L1', 'U2-L1'},
        canDoIds: {'X.LISTENING.1', 'X.R.1'},
      ),
      current: _snap(),
    );
    expect(violations, hasLength(3));
  });

  test('mergeForPublication adds what is new and keeps what was published', () {
    final merged = mergeForPublication(
      published: _snap(
        activities: {
          _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
        },
      ),
      current: _snap(
        units: {'U1', 'U2'},
        activities: {
          _a01: PublishedActivity(
            mode: 'mastery',
            canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
          ),
        },
      ),
    );
    expect(merged.unitIds, {'U1', 'U2'});
    expect(merged.activities[_a01]!.canDo, {'X.LISTENING.1', 'X.LISTENING.2'});
  });

  test('mergeForPublication refuses to launder a removal into the snapshot', () {
    // This is the whole point of the script being a merge. If regenerating
    // the snapshot could erase an id, the gate would be one command away
    // from meaningless.
    expect(
      () => mergeForPublication(
        published: _snap(
          activities: {
            _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
          },
        ),
        current: _snap(activities: const {}),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('a snapshot survives a round trip through JSON', () {
    final snapshot = _snap(
      activities: {
        _a01: PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'}),
      },
    );
    final restored = PublishedIdSnapshot.fromJson(snapshot.toJson());
    expect(
      publicationViolations(published: snapshot, current: restored),
      isEmpty,
    );
    expect(
      publicationViolations(published: restored, current: snapshot),
      isEmpty,
    );
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/content/publication/published_id_snapshot_test.dart`
Expected: FAIL — `published_id_snapshot.dart` does not exist.

- [ ] **Step 3: Write the implementation**

```dart
// lib/content/publication/published_id_snapshot.dart
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

class PublishedIdSnapshot {
  const PublishedIdSnapshot({
    required this.courseId,
    required this.unitIds,
    required this.lessonIds,
    required this.activities,
    required this.canDoIds,
  });

  factory PublishedIdSnapshot.fromBundle(CourseBundle bundle) {
    final activities = <String, PublishedActivity>{};
    final canDoIds = <String>{};
    for (final unit in bundle.units) {
      canDoIds.addAll(unit.mastery.requiredObjectives);
      for (final lesson in unit.lessons) {
        canDoIds.addAll(lesson.canDo);
        for (final a in lesson.activities) {
          canDoIds.addAll(a.canDo);
          activities[a.id] = PublishedActivity(
            mode: a.mode.name,
            canDo: a.canDo.toSet(),
          );
        }
      }
    }
    return PublishedIdSnapshot(
      courseId: bundle.course.id,
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
  final Set<String> unitIds;
  final Set<String> lessonIds;
  final Map<String, PublishedActivity> activities;
  final Set<String> canDoIds;

  /// Sorted on the way out so the committed file has a stable diff — a
  /// snapshot that reorders itself on every regeneration is a snapshot
  /// nobody reviews.
  Map<String, dynamic> toJson() => {
    'courseId': courseId,
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

/// Every way [current] is an illegal successor to [published].
///
/// Legal: anything added. Illegal: an id that disappeared, a `mode` that
/// changed, an objective an activity no longer carries.
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
/// everything new. Throws rather than laundering a removal.
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
  return PublishedIdSnapshot(
    courseId: current.courseId,
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
```

- [ ] **Step 4: Run it and watch it pass**

Run: `flutter test test/content/publication/published_id_snapshot_test.dart`
Expected: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/content/publication test/content/publication
git commit -m "feat: define what may and may not change about a published id"
```

---

### Task 2: The script, and the two committed snapshots

**Files:**
- Create: `tool/update_published_ids.dart`
- Create: `test/content/published/a1-published-ids.json`, `test/content/published/a2-published-ids.json` (generated by the script, then committed)

**Interfaces:**
- Consumes: `PublishedIdSnapshot`, `mergeForPublication` (Task 1).

- [ ] **Step 1: Write the script**

```dart
// tool/update_published_ids.dart
//
// Records the ids the shipped bundles now publish.
//
//   dart run tool/update_published_ids.dart
//
// Run this after ADDING content, and commit the diff it produces. It
// merges: it will never drop an id, change a published mode, or drop a
// published objective — if the bundle did any of those, it prints what and
// exits non-zero rather than writing. Retiring a published id is a
// deliberate act that means hand-editing the JSON, and the reviewer of
// that commit should be able to say why.
import 'dart:convert';
import 'dart:io';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

const _levels = {
  'a1': 'assets/content/en/A1/a1-course-bundle.json',
  'a2': 'assets/content/en/A2/a2-course-bundle.json',
};

void main() {
  var failed = false;
  for (final entry in _levels.entries) {
    final bundle = CourseBundleParser.parse(
      File(entry.value).readAsStringSync(),
    );
    final current = PublishedIdSnapshot.fromBundle(bundle);
    final file = File('test/content/published/${entry.key}-published-ids.json');

    PublishedIdSnapshot next;
    if (file.existsSync()) {
      final published = PublishedIdSnapshot.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      try {
        next = mergeForPublication(published: published, current: current);
      } on StateError catch (e) {
        stderr.writeln('${entry.key}: ${e.message}');
        failed = true;
        continue;
      }
    } else {
      next = current;
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(next.toJson())}\n',
    );
    stdout.writeln(
      '${entry.key}: ${next.activities.length} activities, '
      '${next.unitIds.length} units',
    );
  }
  if (failed) exit(1);
}
```

- [ ] **Step 2: Run it and inspect what it wrote**

```bash
dart run tool/update_published_ids.dart
git status --short
```

Expected: two new JSON files. Check by hand that A2's activity count is 432 and its unit count 12, and that A1's counts match its bundle — a snapshot of the wrong file protects nothing.

- [ ] **Step 3: Prove the script refuses a removal**

Delete one activity from the A2 bundle in the working tree, re-run the script, and confirm it prints that activity's id and exits 1 **without writing**. Restore with `git checkout -- assets/`. Record the observed output in your report — this is the one behaviour that makes the whole gate worth having, so seeing it fail is not optional.

- [ ] **Step 4: Commit**

```bash
git add tool/ test/content/published/
git commit -m "feat: record the ids A1 and A2 have published"
```

---

### Task 3: The gate

**Files:**
- Create: `test/content/published_id_stability_test.dart`

**Interfaces:**
- Consumes: Task 1's functions, Task 2's JSON files.

Two directions, and both matter:

- **Stability** (the gate): the bundle must be a legal successor to the snapshot. This is what stops a removal, a mode change or a dropped tag.
- **Completeness** (the forcing function): the snapshot must name everything the bundle now has. Without it, a new unit is unprotected until somebody remembers to run the script — and nobody would, because nothing would fail.

- [ ] **Step 1: Write the test**

```dart
// test/content/published_id_stability_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

/// Ids are permanent once a level ships. `activity_attempts` stores them as
/// plain strings with no foreign key, so a learner's recorded evidence
/// outlives the content it points at: a reused id re-attributes their work,
/// a changed mode re-counts it, a dropped objective strands it.
///
/// `test/content/published/*.json` is the record of what shipped. Run
/// `dart run tool/update_published_ids.dart` after adding content and
/// commit the diff.
const _levels = {
  'a1': 'assets/content/en/A1/a1-course-bundle.json',
  'a2': 'assets/content/en/A2/a2-course-bundle.json',
};

PublishedIdSnapshot _published(String levelId) => PublishedIdSnapshot.fromJson(
  jsonDecode(
        File(
          'test/content/published/$levelId-published-ids.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

PublishedIdSnapshot _current(String levelId) => PublishedIdSnapshot.fromBundle(
  CourseBundleParser.parse(File(_levels[levelId]!).readAsStringSync()),
);

void main() {
  for (final levelId in _levels.keys) {
    group(levelId.toUpperCase(), () {
      test('the published snapshot exists and is not empty', () {
        // First, because every check below iterates it: an empty snapshot
        // would make them all pass while protecting nothing.
        final published = _published(levelId);
        expect(published.activities, isNotEmpty);
        expect(published.unitIds, isNotEmpty);
      });

      test('nothing published has been removed, re-moded or un-tagged', () {
        final violations = publicationViolations(
          published: _published(levelId),
          current: _current(levelId),
        );
        expect(
          violations,
          isEmpty,
          reason:
              'ids are permanent after publication:\n'
              '${violations.join('\n')}',
        );
      });

      test('the snapshot covers everything the bundle now publishes', () {
        // The forcing function. Content added without re-running the
        // script would otherwise sit outside the guard indefinitely.
        final violations = publicationViolations(
          published: _current(levelId),
          current: _published(levelId),
        );
        expect(
          violations,
          isEmpty,
          reason:
              'the published snapshot is behind the bundle. Run '
              '`dart run tool/update_published_ids.dart` and commit the '
              'diff:\n${violations.join('\n')}',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Run it**

Run: `flutter test test/content/published_id_stability_test.dart`
Expected: PASS, 6 tests. If the completeness test fails, the snapshot is behind — re-run the script.

- [ ] **Step 3: Prove it catches all four failures**

One at a time, against the working tree, confirming the failure message names the offender, then `git checkout -- assets/`:

1. Delete one A2 activity → the removal test fails naming its id.
2. Change one A2 activity's `"mode": "mastery"` to `"practice"` → fails naming both modes.
3. Remove one entry from an A2 activity's `"canDo"` array → fails naming the objective.
4. Add a new activity to an A2 lesson → the **completeness** test fails telling you to run the script.

Record all four observed messages in your report. A gate nobody has watched fail is a gate nobody knows works.

- [ ] **Step 4: Commit**

```bash
git add test/content/published_id_stability_test.dart
git commit -m "test: ids are permanent once a level has shipped"
```

---

### Task 4: Write the policy down where it is followed

**Files:**
- Modify: `docs/CONVENTIONS.md`, `docs/DATA_MODEL.md`, `docs/TESTING.md`, `README.md`

Derive the full list from CLAUDE.md's Definition-of-done table rather than this one, and give one line of reasoning in your report for each row you rule non-applicable.

- [ ] **Step 1: CONVENTIONS.md — the rule**

Under the id-naming material, state the policy in the terms the gate enforces: after a level is published, ids are permanent, an activity's `mode` is frozen, and its `canDo` list is append-only. Name the consequence for each (re-attributed evidence, re-counted mastery, stranded evidence), name the gate that enforces it, and say what to do instead — retiring content means leaving the id in place or minting a new one.

- [ ] **Step 2: DATA_MODEL.md — how it is enforced**

`DATA_MODEL.md` already asserts ids are stable across content versions. Say what now makes that true: the committed snapshot, the gate, and the regeneration command.

- [ ] **Step 3: TESTING.md and README.md — the command**

`dart run tool/update_published_ids.dart`, when to run it (after adding content), and what a failure means. README's command list gains the same line.

- [ ] **Step 4: Full suite, then commit**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

```bash
git add docs/ README.md
git commit -m "docs: state the post-publication id policy and where it is enforced"
```

Bump each edited doc's **Last verified** line to the day of the edit, naming the change and the branch, in that file's own style.

---

## Self-review notes

- **The script is a merge, not a regeneration.** This is the single design decision that decides whether the gate is real. A regenerating script would make every failure fixable with one command, and that is precisely what the guard exists to prevent.
- **Both directions are tested** because only one of them is a gate. Stability without completeness protects a shrinking fraction of the content as the course grows.
- **Task 2 Step 3 and Task 3 Step 3 are mutation tests**, not formalities. Every gate in `test/content/` that was found fakeable this month passed its own suite at the time.
- **A1 is snapshotted too**, even though it shipped long before this guard existed. The snapshot then records A1 as it is today rather than as first published — which is the best available record, and must be stated as such in the docs so nobody later mistakes it for a launch-day artifact.
