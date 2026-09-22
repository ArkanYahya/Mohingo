# Content Versioning and Stale Units — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the content-versioning layer real — record each bundle's id snapshot when it loads, detect when updated content has moved out from under a learner's recorded progress, and tell the learner.

**Architecture:** A pure domain function diffs a previously recorded id snapshot against the newly loaded index and returns the units whose evidence no longer matches the content. A provider in the progress feature drives it: `latest()` is read **before** `recordIfNew()`, so the comparison has something to compare against. The unit row on the Learn tab is where a stale unit tells the learner, reusing the existing status-line slot.

**Tech Stack:** Dart/Flutter, Drift (`content_versions`, `unit_progress`, `activity_attempts`), Riverpod 3 with `riverpod_annotation` codegen, `flutter_test`.

**Spec:** No design doc — this plan is the design. It implements behaviour that `docs/DATA_MODEL.md` already describes as existing (see Task 7, which corrects that), and the intent recorded in `lib/features/progress/domain/repositories/content_version_repository.dart`'s doc comment.

## Global Constraints

- The app works fully offline; nothing here may require network. See [ADR 0001](../../adr/0001-offline-first-firebase-only-backend.md).
- `lib/content/` never imports `lib/features/` ([ARCHITECTURE.md:38](../../ARCHITECTURE.md)). The hook therefore lives in `lib/features/progress/`, not in `courseContentProvider`.
- All user-facing copy is bilingual, Arabic written natively for Arabic rather than translated from the English. An Arabic noun precedes a Latin level code (`المستوى A2`), never a bare code at a sentence boundary.
- Never hardcode left/right — directional (`start`/`end`) properties only.
- No new dependency. l10n codegen is `flutter gen-l10n`, not build_runner. Drift and Riverpod codegen is `dart run build_runner build --delete-conflicting-outputs`.
- A unit's `state` is a recommendation, never a lock ([PRODUCT.md](../../PRODUCT.md) flow 5). Staleness must not block a learner from anything.

---

## Why this is worth building

Verified in this repo at `c834e42`:

- `contentVersionRepositoryProvider` (`lib/features/progress/providers/progress_providers.dart:52`) has **zero** consumers — the only matches in `lib/` are inside its own generated file.
- `DriftContentVersionRepository.recordIfNew()` is fully implemented and **never called**, so `content_versions` is empty on every install.
- `unit_progress.isContentStale` (`lib/data/local/tables/lesson_progress_tables.dart:23`) is **never written** anywhere in `lib/`; it appears once more in the whole repo, as `false` in a test fixture.

So the column, the table, the repository and its provider all exist, and none of them does anything. This plan connects them.

**What "stale" means here.** Two conditions, both checked against the learner's own recorded progress:

1. An activity the learner has an attempt for no longer exists in the loaded bundle. Their evidence is stranded — `MasteryAggregationService` still counts it, but the activity it points at is gone, and the answer-review screen renders the gap as "Not answered".
2. A Can-Do objective a unit requires no longer exists, or the unit now requires one it did not before. The bar moved after they cleared it.

Anything else — a reworded prompt, a longer transcript, a new activity added — is not staleness. Content improving is normal and must not nag.

## File structure

| File | Responsibility |
|---|---|
| `lib/features/progress/domain/content_drift.dart` | **New.** Pure functions: diff a recorded snapshot against a loaded index, and decide which units that makes stale. No Drift, no Riverpod, no I/O — so it is testable as data in, data out. |
| `lib/features/progress/data/drift_activity_attempt_repository.dart` | **Modify.** Add `attemptedActivityIds({required int learnerId})` — the one query the diff needs and nothing today provides. |
| `lib/features/progress/data/drift_unit_lesson_progress_repository.dart` | **Modify.** Add `markUnitsContentStale(...)` so the flag can be written and cleared. |
| `lib/features/progress/domain/repositories/*.dart` | **Modify.** The two interfaces above gain the same signatures. |
| `lib/features/progress/providers/content_version_providers.dart` | **New.** Watches a level's index, reads `latest()` first, records, diffs, writes the flags. The ordering lives here and nowhere else. |
| `lib/features/learning_path/presentation/course_screen.dart` | **Modify.** A stale unit says so on its row. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` | **Modify.** One string, both languages. |
| `test/features/progress/domain/content_drift_test.dart` | **New.** The diff, as data. |
| `test/features/progress/content_staleness_test.dart` | **New.** Against a real prior-version row, in the style of `test/data/local/database_test.dart` — never against a fresh install. |

---

### Task 1: The diff, as a pure function

**Files:**
- Create: `lib/features/progress/domain/content_drift.dart`
- Test: `test/features/progress/domain/content_drift_test.dart`

**Interfaces:**
- Produces:
  - `class ContentDrift { final Set<String> removedActivityIds; final Set<String> removedCanDoIds; final Set<String> addedCanDoIds; bool get isEmpty; }`
  - `ContentDrift contentDriftBetween({required ContentVersion previous, required CourseContentIndex current})`
  - `Set<String> staleUnitIds({required ContentDrift drift, required Set<String> attemptedActivityIds, required Map<String, String> unitIdByActivityId, required CourseContentIndex current})`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/progress/domain/content_drift_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/domain/content_drift.dart';

ContentVersion _snapshot({
  List<String> activityIds = const [],
  List<String> canDoIds = const [],
}) => ContentVersion(
  id: 1,
  contentVersion: 'EN-A2-V1',
  schemaVersion: '2.0.0',
  courseId: 'EN-A2-V1',
  installedAt: DateTime.utc(2026, 9, 1),
  unitIdsJson: jsonEncode(const <String>[]),
  lessonIdsJson: jsonEncode(const <String>[]),
  activityIdsJson: jsonEncode(activityIds),
  canDoIdsJson: jsonEncode(canDoIds),
);

void main() {
  test('an unchanged bundle drifts in no way at all', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A', 'B'], canDoIds: ['X']),
      currentActivityIds: {'A', 'B'},
      currentCanDoIds: {'X'},
    );
    expect(drift.isEmpty, isTrue);
  });

  test('content that only grows is not drift — added activities and '
      'objectives are a normal content update', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A'], canDoIds: ['X']),
      currentActivityIds: {'A', 'B'},
      currentCanDoIds: {'X', 'Y'},
    );
    expect(drift.removedActivityIds, isEmpty);
    expect(drift.removedCanDoIds, isEmpty);
    expect(drift.addedCanDoIds, {'Y'});
  });

  test('a removed activity and a removed objective are both drift', () {
    final drift = contentDriftFromIds(
      previous: _snapshot(activityIds: ['A', 'B'], canDoIds: ['X', 'Y']),
      currentActivityIds: {'A'},
      currentCanDoIds: {'X'},
    );
    expect(drift.removedActivityIds, {'B'});
    expect(drift.removedCanDoIds, {'Y'});
    expect(drift.isEmpty, isFalse);
  });

  test('only a unit the learner actually attempted goes stale', () {
    final stale = staleUnitIds(
      drift: ContentDrift(
        removedActivityIds: {'A2-U1-L1-A01', 'A2-U5-L1-A01'},
        removedCanDoIds: const {},
        addedCanDoIds: const {},
      ),
      attemptedActivityIds: {'A2-U1-L1-A01'},
      unitIdByActivityId: {
        'A2-U1-L1-A01': 'A2-U1',
        'A2-U5-L1-A01': 'A2-U5',
      },
      requiredObjectivesByUnitId: const {},
    );
    // U5's activity vanished too, but the learner never answered it, so
    // nothing of theirs is stranded and there is nothing to tell them.
    expect(stale, {'A2-U1'});
  });

  test("a unit whose required objectives changed is stale even if the "
      "learner's own answers are all still there", () {
    final stale = staleUnitIds(
      drift: ContentDrift(
        removedActivityIds: const {},
        removedCanDoIds: {'A2.U3.WRITING.OLD'},
        addedCanDoIds: {'A2.U3.WRITING.NEW'},
      ),
      attemptedActivityIds: const {},
      unitIdByActivityId: const {},
      requiredObjectivesByUnitId: {
        'A2-U3': {'A2.U3.WRITING.NEW'},
        'A2-U7': {'A2.U7.READING.UNCHANGED'},
      },
    );
    expect(stale, {'A2-U3'});
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/features/progress/domain/content_drift_test.dart`
Expected: FAIL — `content_drift.dart` does not exist.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/progress/domain/content_drift.dart
import 'dart:convert';

import '../../../content/index/course_content_index.dart';
import '../../../data/local/database.dart';

/// What changed between the content a learner's progress was recorded
/// against and the content now loaded.
///
/// Only *losses* count. Content that grows — a new activity, a new
/// objective — is a normal update and must never nag a learner, so
/// `addedCanDoIds` is carried for one narrow purpose: a unit whose
/// required objectives changed has moved its own bar, which the learner
/// deserves to know even though nothing of theirs was lost.
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

Set<String> _decode(String json) =>
    (jsonDecode(json) as List).cast<String>().toSet();

/// The id-level diff. Split from [contentDriftBetween] so it can be
/// tested without building a whole index.
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
  required CourseContentIndex current,
}) {
  final canDoIds = <String>{
    for (final unit in current.bundle.units)
      for (final lesson in unit.lessons) ...lesson.canDo,
  };
  return contentDriftFromIds(
    previous: previous,
    currentActivityIds: current.activitiesById.keys.toSet(),
    currentCanDoIds: canDoIds,
  );
}

/// The units this drift actually affects for *this* learner.
///
/// A unit is stale when the learner has an answer recorded against an
/// activity that no longer exists (their evidence is stranded), or when
/// the unit's required objectives are not the ones it required when they
/// worked on it (the bar moved under them). A unit whose content changed
/// in ways the learner never touched is not stale: there is nothing to
/// tell them.
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
```

Note the test calls `staleUnitIds` with `requiredObjectivesByUnitId` — add that parameter to the test's earlier call too (`requiredObjectivesByUnitId: const {}`), which the test above already does.

- [ ] **Step 4: Run it and watch it pass**

Run: `flutter test test/features/progress/domain/content_drift_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/domain/content_drift.dart test/features/progress/domain/content_drift_test.dart
git commit -m "feat: work out what a content update took away from a learner"
```

---

### Task 2: The two queries the diff needs

**Files:**
- Modify: `lib/features/progress/domain/repositories/activity_attempt_repository.dart`, `lib/features/progress/data/drift_activity_attempt_repository.dart`
- Modify: `lib/features/progress/domain/repositories/unit_lesson_progress_repository.dart`, `lib/features/progress/data/drift_unit_lesson_progress_repository.dart`
- Test: `test/features/progress/data/content_staleness_queries_test.dart`

**Interfaces:**
- Produces:
  - `Future<Set<String>> attemptedActivityIds({required int learnerId})`
  - `Future<void> markUnitsContentStale({required int learnerId, required Set<String> unitIds})` — sets the flag on the named units and **clears it on every other unit of that learner**, so a later bundle that puts things right un-flags them.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/progress/data/content_staleness_queries_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';

void main() {
  late AppDatabase db;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(uuid: 'l', createdAt: DateTime.utc(2026)),
        );
  });
  tearDown(() => db.close());

  test('attemptedActivityIds returns every activity this learner answered, '
      'once each', () async {
    final attempts = DriftActivityAttemptRepository(db);
    for (final id in ['A2-U1-L1-A01', 'A2-U1-L1-A01', 'A2-U1-L2-A03']) {
      await attempts.recordAttempt(
        learnerId: learnerId,
        activityId: id,
        lessonId: 'A2-U1-L1',
        unitId: 'A2-U1',
        mode: 'mastery',
        evidenceSkill: Skill.reading,
        isCorrect: true,
        score: 1,
        canDoIds: const [],
      );
    }
    expect(
      await attempts.attemptedActivityIds(learnerId: learnerId),
      {'A2-U1-L1-A01', 'A2-U1-L2-A03'},
    );
  });

  test('marking units stale also clears the flag on units that are not', () async {
    final progress = DriftUnitLessonProgressRepository(db);
    for (final unitId in ['A2-U1', 'A2-U2']) {
      await progress.upsertUnitProgress(
        learnerId: learnerId,
        unitId: unitId,
        state: 'inProgress',
      );
    }

    await progress.markUnitsContentStale(
      learnerId: learnerId,
      unitIds: {'A2-U1'},
    );
    var rows = {
      for (final r in await progress.allUnitProgress(learnerId: learnerId))
        r.unitId: r.isContentStale,
    };
    expect(rows, {'A2-U1': true, 'A2-U2': false});

    // A later bundle restores what was missing: nothing is stale now, and
    // the flag must come back off rather than stick forever.
    await progress.markUnitsContentStale(
      learnerId: learnerId,
      unitIds: const {},
    );
    rows = {
      for (final r in await progress.allUnitProgress(learnerId: learnerId))
        r.unitId: r.isContentStale,
    };
    expect(rows, {'A2-U1': false, 'A2-U2': false});
  });
}
```

Check `recordAttempt`'s real signature in `drift_activity_attempt_repository.dart:17` before running — match it exactly rather than the shape sketched here, and adjust the test's call if it differs.

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/features/progress/data/content_staleness_queries_test.dart`
Expected: FAIL — neither method exists.

- [ ] **Step 3: Implement both, interface first**

```dart
// in ActivityAttemptRepository
/// Every activity id this learner has an attempt for. Used to decide
/// whether a content update stranded any of their evidence.
Future<Set<String>> attemptedActivityIds({required int learnerId});
```

```dart
// in DriftActivityAttemptRepository
@override
Future<Set<String>> attemptedActivityIds({required int learnerId}) async {
  final query = _db.selectOnly(_db.activityAttempts, distinct: true)
    ..addColumns([_db.activityAttempts.activityId])
    ..where(_db.activityAttempts.learnerId.equals(learnerId));
  final rows = await query.get();
  return rows
      .map((r) => r.read(_db.activityAttempts.activityId)!)
      .toSet();
}
```

```dart
// in UnitLessonProgressRepository
/// Flags exactly [unitIds] as having content that moved under the
/// learner, and clears the flag on all their other units — a later
/// bundle that restores what was missing must un-flag them.
Future<void> markUnitsContentStale({
  required int learnerId,
  required Set<String> unitIds,
});
```

```dart
// in DriftUnitLessonProgressRepository
@override
Future<void> markUnitsContentStale({
  required int learnerId,
  required Set<String> unitIds,
}) async {
  await _db.transaction(() async {
    await (_db.update(_db.unitProgress)
          ..where((t) => t.learnerId.equals(learnerId)))
        .write(const UnitProgressCompanion(isContentStale: Value(false)));
    if (unitIds.isEmpty) return;
    await (_db.update(_db.unitProgress)..where(
          (t) => t.learnerId.equals(learnerId) & t.unitId.isIn(unitIds),
        ))
        .write(const UnitProgressCompanion(isContentStale: Value(true)));
  });
}
```

- [ ] **Step 4: Run it and watch it pass**

Run: `flutter test test/features/progress/data/content_staleness_queries_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress test/features/progress/data/content_staleness_queries_test.dart
git commit -m "feat: query a learner's answered activities, and flag units whose content moved"
```

---

### Task 3: Record on load, and flag what drifted

**Files:**
- Create: `lib/features/progress/providers/content_version_providers.dart`
- Test: `test/features/progress/content_staleness_test.dart`

**Interfaces:**
- Consumes: `contentDriftBetween`, `staleUnitIds` (Task 1); `attemptedActivityIds`, `markUnitsContentStale` (Task 2); `contentVersionRepositoryProvider`, `currentLearnerProvider`, `courseContentProvider`.
- Produces: `Future<Set<String>> recordContentVersionAndFlagDrift(Ref ref, String levelId)` exposed as `recordContentVersionAndFlagDriftProvider(levelId)`, returning the unit ids it flagged.

**The ordering is the whole task.** `latest()` must be read *before* `recordIfNew()`. Record first and the "previous" row is the version you just wrote, the diff is always empty, and the feature silently never fires — which is exactly how a test that only runs on a fresh install would pass while the feature does nothing.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/progress/content_staleness_test.dart
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/providers/content_version_providers.dart';

void main() {
  test('a learner whose answered activity vanished from the new bundle has '
      'that unit flagged, and only that unit', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(uuid: 'l', createdAt: DateTime.utc(2026)),
        );

    // The prior-version snapshot: the shipped A2 bundle exactly as it is,
    // plus one activity id that this "older" version had and the current
    // one does not. Built from the real bundle rather than a fixture, in
    // the spirit of database_test.dart testing migrations against a real
    // prior shape rather than against onCreate.
    final index = await loadA2IndexForTest();
    final retired = 'A2-U1-L1-A99';
    await db
        .into(db.contentVersions)
        .insert(
          ContentVersionsCompanion.insert(
            contentVersion: 'A2-OLD',
            schemaVersion: index.bundle.schemaVersion,
            courseId: index.bundle.course.id,
            installedAt: DateTime.utc(2026, 9, 1),
            unitIdsJson: jsonEncode(index.unitsById.keys.toList()),
            lessonIdsJson: jsonEncode(index.lessonsById.keys.toList()),
            activityIdsJson: jsonEncode([
              ...index.activitiesById.keys,
              retired,
            ]),
            canDoIdsJson: jsonEncode(<String>[]),
          ),
        );

    // The learner answered the activity that is now gone, and one that
    // still exists in another unit.
    final attempts = DriftActivityAttemptRepository(db);
    await attempts.recordAttempt(/* retired, unit A2-U1 — real signature */);
    final progress = DriftUnitLessonProgressRepository(db);
    await progress.upsertUnitProgress(
      learnerId: learnerId,
      unitId: 'A2-U1',
      state: 'mastered',
    );
    await progress.upsertUnitProgress(
      learnerId: learnerId,
      unitId: 'A2-U2',
      state: 'mastered',
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final flagged = await container.read(
      recordContentVersionAndFlagDriftProvider('a2').future,
    );

    expect(flagged, {'A2-U1'});
    final rows = {
      for (final r in await progress.allUnitProgress(learnerId: learnerId))
        r.unitId: r.isContentStale,
    };
    expect(rows['A2-U1'], isTrue);
    expect(rows['A2-U2'], isFalse);
  });

  test('the current version is recorded, and a second load of the same '
      'version flags nothing new', () async {
    // Proves the ordering: if recordIfNew ran before latest(), the first
    // load would compare the new version against itself and this test
    // would pass for the wrong reason — so assert the *first* load on a
    // fresh install flags nothing AND writes exactly one row, then that a
    // second load still finds one row.
  });
}
```

Write the second test out in full when you implement; the comment states what it must prove. Provide `loadA2IndexForTest()` in the test file by parsing `assets/content/en/A2/a2-course-bundle.json` with `CourseBundleParser`, as `test/content/a2_finished_units.dart` does.

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/features/progress/content_staleness_test.dart`
Expected: FAIL — the provider does not exist.

- [ ] **Step 3: Write the provider**

```dart
// lib/features/progress/providers/content_version_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/providers/course_content_providers.dart';
import '../data/drift_activity_attempt_repository.dart';
import '../domain/content_drift.dart';
import 'current_learner_provider.dart';
import 'progress_providers.dart';

part 'content_version_providers.g.dart';

/// Records the loaded bundle's id snapshot and flags any unit whose
/// content moved under this learner. Returns the flagged unit ids.
///
/// The read of [ContentVersionRepository.latest] happens **before**
/// [ContentVersionRepository.recordIfNew]. Reversed, the "previous"
/// snapshot would be the one just written, every diff would be empty, and
/// this would quietly do nothing for the rest of the app's life.
@riverpod
Future<Set<String>> recordContentVersionAndFlagDrift(
  Ref ref,
  String levelId,
) async {
  final index = await ref.watch(courseContentProvider(levelId).future);
  final learner = await ref.watch(currentLearnerProvider.future);
  final versions = ref.watch(contentVersionRepositoryProvider);
  final courseId = index.bundle.course.id;

  final previous = await versions.latest(courseId: courseId);

  await versions.recordIfNew(
    contentVersion: index.bundle.contentVersion,
    schemaVersion: index.bundle.schemaVersion,
    courseId: courseId,
    unitIds: index.unitsById.keys.toList(),
    lessonIds: index.lessonsById.keys.toList(),
    activityIds: index.activitiesById.keys.toList(),
    canDoIds: [
      for (final unit in index.bundle.units)
        for (final lesson in unit.lessons) ...lesson.canDo,
    ],
  );

  // Nothing recorded before means this is a first install: there is no
  // "before" to have drifted from.
  if (previous == null ||
      previous.contentVersion == index.bundle.contentVersion) {
    return const {};
  }

  final drift = contentDriftBetween(previous: previous, current: index);
  if (drift.isEmpty) return const {};

  final attempts = ref.watch(activityAttemptRepositoryProvider);
  final progress = ref.watch(unitLessonProgressRepositoryProvider);

  final stale = staleUnitIds(
    drift: drift,
    attemptedActivityIds: await attempts.attemptedActivityIds(
      learnerId: learner.id,
    ),
    unitIdByActivityId: {
      for (final unit in index.bundle.units)
        for (final lesson in unit.lessons)
          for (final a in lesson.activities) a.id: unit.id,
    },
    requiredObjectivesByUnitId: {
      for (final unit in index.bundle.units)
        unit.id: unit.mastery.requiredObjectives.toSet(),
    },
  );

  await progress.markUnitsContentStale(
    learnerId: learner.id,
    unitIds: stale,
  );
  return stale;
}
```

Check the real provider names for the attempt and progress repositories in `progress_providers.dart` and use those; the names above are the expected ones, not verified.

- [ ] **Step 4: Generate, run, and watch it pass**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/progress/content_staleness_test.dart
```
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/providers test/features/progress/content_staleness_test.dart
git commit -m "feat: record each bundle's ids on load, and notice what a learner lost"
```

---

### Task 4: Fire it when a level loads

**Files:**
- Modify: `lib/app.dart` (or wherever `ensureLevelEnrolmentProvider` is fired — find it and follow that pattern)
- Test: extend `test/widget_test.dart`

**Interfaces:**
- Consumes: `recordContentVersionAndFlagDriftProvider` (Task 3).

- [ ] **Step 1: Find the existing pattern**

`lib/app.dart` already fires `ensureLevelEnrolmentProvider` for the current level as soon as the profile and that level's content are ready. Read it. This provider fires the same way and in the same place — one more `ref.watch`, not a new mechanism.

- [ ] **Step 2: Write the failing test**

Add to `test/widget_test.dart`, following `_pumpAppAndWaitForContent`:

```dart
  testWidgets('loading the app records the bundle it loaded', (tester) async {
    final prefs = await _mockPrefs();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await _pumpAppAndWaitForContent(
      tester,
      prefs,
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    final rows = await db.select(db.contentVersions).get();
    expect(
      rows.map((r) => r.courseId),
      contains('EN-A1-V2'),
      reason: 'content_versions was empty on every install before this',
    );
  });
```

Confirm A1's real `course.id` from the bundle before writing the expectation.

- [ ] **Step 3: Run it and watch it fail**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — no rows; the table is empty.

- [ ] **Step 4: Fire the provider, run, and watch it pass**

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart test/widget_test.dart
git commit -m "feat: record the loaded bundle when the app starts"
```

---

### Task 5: Tell the learner

**Files:**
- Modify: `lib/features/learning_path/presentation/course_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Test: `test/features/learning_path/presentation/course_screen_test.dart`

**What to say, and what not to.** A stale unit is not an error and not the learner's fault, and it must not imply their progress was lost — it wasn't. The unit row already carries a status line ("Mastered", "Needs review", "7 lessons · 70–100 min"); this is one more line in that slot.

- [ ] **Step 1: Add the copy**

`lib/l10n/app_en.arb`:

```json
  "learnUnitContentUpdated": "Updated since you finished it",
  "@learnUnitContentUpdated": {
    "description": "Status line on a unit whose content changed after the learner worked through it. Their progress is kept; some of what they answered may no longer be in the unit."
  }
```

`lib/l10n/app_ar.arb`:

```json
  "learnUnitContentUpdated": "تغيّر محتوى الوحدة بعد أن أنهيتها"
```

The Arabic is written as Arabic, not as a rendering of the English: it says plainly that the unit's content changed after you finished it, which is the fact the learner needs.

Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing test**

```dart
  testWidgets('a unit whose content moved under the learner says so', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester, staleUnitIds: const {'A1-U1'});

    expect(find.text(l10n.learnUnitContentUpdated), findsOneWidget);
  });

  testWidgets('a unit that did not drift says nothing about it', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester);

    expect(find.text(l10n.learnUnitContentUpdated), findsNothing);
  });
```

`_pump` gains a `Set<String> staleUnitIds = const {}` parameter that seeds `isContentStale` on those units' progress rows. **Both tests matter**: the second is what proves the line does not appear on every unit, which is the failure mode a single positive test would miss.

- [ ] **Step 3: Run, implement, run**

Read `_UnitSummary`/`_UnitRow` around `course_screen.dart:500-520`, where the existing status labels are chosen, and add this one alongside them from the unit's `isContentStale`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/learning_path lib/l10n lib/core/l10n test/features/learning_path
git commit -m "feat: a unit says when its content changed after the learner finished it"
```

---

### Task 6: Prove it against a real prior version, not a fresh install

**Files:**
- Test: `test/features/progress/content_staleness_test.dart` (extend)

The plan's riskiest assumption is that this works on an *upgrade*, and every test so far builds its own prior snapshot. `test/data/local/database_test.dart` tests migrations by hand-building the previous schema rather than trusting `onCreate`; do the equivalent here.

- [ ] **Step 1: Add the upgrade test**

Record the A1 bundle's real snapshot as version 1. Then present a "new" index with one unit's activity removed — build it by parsing the real bundle and dropping one activity before `CourseContentIndex.build`. Assert: the learner who answered the dropped activity has that unit and only that unit flagged; a learner with no attempts has nothing flagged; and running the same load twice does not change the result.

- [ ] **Step 2: Run the whole suite**

```bash
dart format .
flutter analyze
flutter test
```
Expected: all green, 770 + your new tests.

- [ ] **Step 3: Commit**

```bash
git add test/features/progress/content_staleness_test.dart
git commit -m "test: prove stale detection on an upgrade, not a fresh install"
```

---

### Task 7: Correct the documents

**Files:**
- Modify: `docs/DATA_MODEL.md`, `docs/ARCHITECTURE.md`, `docs/UX_PRINCIPLES.md`, `docs/TESTING.md`

Derive the full list from CLAUDE.md's Definition-of-done table rather than this one, and give one line of reasoning in your report for each row you rule non-applicable.

- [ ] **Step 1: Fix DATA_MODEL.md's `content_versions` entry**

It currently states an intention as a behaviour: *"the id-set snapshots are what makes detecting removed ids possible when content updates later."* Until this plan landed, nothing wrote to that table and nothing read it. Say what is now true: the snapshot is recorded when a level's bundle loads, the next load diffs against it, and a unit is flagged `isContentStale` when the learner has an answer against an activity that is gone or the unit's required objectives moved.

- [ ] **Step 2: The rest**

ARCHITECTURE — the new provider and why the hook lives in the progress feature rather than in `courseContentProvider` (the content layer may not import features). UX_PRINCIPLES — the new copy and the rule that staleness informs, never blocks. TESTING — that stale detection is tested against a prior-version snapshot, like the migrations are.

Bump each edited doc's **Last verified** line to the day of the edit, naming the change and the branch, in that file's own style.

- [ ] **Step 3: Commit**

```bash
git add docs/
git commit -m "docs: describe content versioning as it now behaves"
```

---

## Self-review notes

- **Task 1 before Task 2 before Task 3** is deliberate: the diff is pure and testable alone, the queries are testable against a real database alone, and only Task 3 combines them — so a failure in the combination is unambiguous.
- **The ordering trap is called out twice** (Task 3's preamble and its doc comment) because it is the one mistake that leaves every test passing and the feature dead.
- **Two negative tests are load-bearing**: "content that only grows is not drift" (Task 1) and "a unit that did not drift says nothing" (Task 5). Without them, a naive implementation that flags everything passes.
- **Not in scope:** over-the-air content updates and moving content to SQLite are open product decisions, and nothing here presumes either. This plan works the same whether the next bundle arrives in an app update or over a network.
