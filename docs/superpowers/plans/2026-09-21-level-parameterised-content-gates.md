# Level-Parameterised Content Gates — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One content gate suite that every level is held to, instead of a hand-written suite that only A2 has.

**Architecture:** The seven `test/content/a2_*` gate files become one suite under `test/content/levels/`, each gate looping over a list of per-level configs. A config carries the numbers a level is judged by — unit shape, skill balance, length bands, vocabulary floor, capstone ids — and, where a level genuinely differs, a **declared exception**: a different value plus a written reason, never a skip. A1 joins the config list, its failures are triaged one by one, and each one ends as a declared exception, a content fix, or a config difference — never as a lowered threshold.

**Tech Stack:** Dart, `flutter_test`. No new dependency, no production code change.

**Spec:** No design doc — this plan is the design. It generalises the rules recorded in `.superpowers/sdd/2026-09-20-a2-step4-pilot-unit-u1/UNIT-AUTHORING-STANDARD.md` (deleted with that branch's workspace; the gates in `test/content/a2_*` are now the only surviving statement of them, which is part of why this work matters).

## Global Constraints

- **No check may be weakened to make a level pass.** A threshold that A1 misses is either a declared exception for A1 with a written reason, or an A1 content defect to fix. It is never lowered for everyone.
- **No level may be skipped.** There is deliberately no `skip` field anywhere in the config. A level with an exception is still checked, against different numbers.
- **A2's results must not change.** The port is a refactor: same rules, same outcomes. Verified by comparing test counts and results before and after.
- Do not re-author A2 content, and do not regenerate any bundle from `reference/`.
- `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test` all pass before any task is called done.

---

## Why this is worth building

Verified in the repo at `c834e42`:

- A2 is gated by **47 tests across 7 files** (`a2_answerable`, `a2_bilingual`, `a2_bundle_loads`, `a2_capstones`, `a2_design_limits`, `a2_masterable`, `a2_structure`), all driven by `a2FinishedUnitIds`.
- A1 — the level that actually ships to every new learner — is gated by **`a1_content_quality_test.dart`, which holds exactly five tests**, plus per-unit mastery *regression* tests that check one unit can be mastered, not that it is well formed.

So the level with two months of gate-hardening behind it is the newer one, and the level a learner meets first has five checks. Everything the A2 gates catch — a listening activity with no transcript, a closed question with no right answer, an English prompt with no Arabic, a mastery requirement a unit cannot evidence, a `speak` rubric carrying `onlineRefinement` — is unchecked on A1 today.

There is a second cost. Every rule the A2 suite encodes is written in seven places as A2-specific code. Adding B1 means writing them an eighth time, and the eighth copy will differ from the seventh in ways nobody notices.

## The two exceptions the product owner has already declared

Both were decided before this plan, and both go in the config as declared exceptions with their reasons, not as changes to A1:

1. **A1-U0 and A1-U1 are shaped differently.** A1-U0 is 5 lessons / 20 activities / 2 encounter–5 practice–13 mastery; A1-U1 is 7 / 30 / 5–7–18. A1-U2 through A1-U12 are all exactly 7 / 36 / 6–12–18, the same as every A2 unit. U0 is an onboarding unit and U1 was authored before the shape settled; re-cutting either would move published activity ids, which the id-stability guard forbids.
2. **A1 tags Can-Do objectives lesson-wide.** A1's activities carry their lesson's full objective list rather than one matched to the activity's own skill. Re-tagging would drop objectives from published activities, which the append-only policy forbids. A1 is therefore checked at lesson granularity instead — see Task 7, which defines a check of equal strength rather than a skip.

## File structure

| File | Responsibility |
|---|---|
| `test/content/levels/level_gate_config.dart` | **New.** `LevelGateConfig`, `UnitShape`, `SkillBalance`, `LengthBandTier`, `DeclaredException`, `CanDoTagging`; the `kLevelGates` list; and `finishedUnits()`/`bandsFor()` helpers. The single place a level's numbers live. |
| `test/content/levels/level_config_test.dart` | **New.** The config's own gate: exceptions name real units, every reason is written, band tiers cover every unit, no two levels share ids. |
| `test/content/levels/level_structure_test.dart` | **New.** From `a2_structure_test.dart` + `a2_bundle_loads_test.dart`. |
| `test/content/levels/level_answerable_test.dart` | **New.** From `a2_answerable_test.dart`. |
| `test/content/levels/level_bilingual_test.dart` | **New.** From `a2_bilingual_test.dart`. |
| `test/content/levels/level_design_limits_test.dart` | **New.** From `a2_design_limits_test.dart`. |
| `test/content/levels/level_masterable_test.dart` | **New.** From `a2_masterable_test.dart`, including the release rule. |
| `test/content/levels/level_capstones_test.dart` + `level_capstone_checks.dart` | **New.** From `a2_capstones_test.dart` + `a2_capstone_checks.dart`. |
| `test/content/a2_*.dart` | **Delete**, in Task 6, only once the ported suite is green and counted. |
| `test/content/a1_content_quality_test.dart` | **Keep.** Its five checks are A1-specific observations, not level rules. |

---

### Task 1: The config, and its own gate

**Files:**
- Create: `test/content/levels/level_gate_config.dart`
- Test: `test/content/levels/level_config_test.dart`

**Interfaces:**
- Produces:
  - `class DeclaredException<T> { final T value; final String reason; }`
  - `class UnitShape { final int lessons, activities, encounter, practice, mastery; }`
  - `class Range { final int min, max; bool contains(int); }`
  - `class SkillBalance { final Range listening, reading, speaking, writing, mediation; }`
  - `class LengthBandTier { final int throughUnitIndex; final Range listening, reading, writing; }`
  - `enum CanDoTagging { perActivitySkill, lessonWide }`
  - `class LevelGateConfig { ... List<Unit> finishedUnits(); CourseBundle bundle(); UnitShape shapeFor(String unitId); SkillBalance balanceFor(String unitId); LengthBandTier bandsFor(String unitId); }`
  - `const List<LevelGateConfig> kLevelGates`
  - `Iterable<Activity> activitiesOf(Unit unit)` (moved from `a2_finished_units.dart`)

**The design decision that makes this honest:** a level never opts out of a check. `DeclaredException` holds a *value* and a *reason*, so an exception says "A1-U0 is 5 lessons, because it is an onboarding unit" — which is still a check, and still fails if A1-U0 becomes 4 lessons. There is no boolean anywhere that turns a gate off.

- [ ] **Step 1: Write the failing test**

```dart
// test/content/levels/level_config_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'level_gate_config.dart';

void main() {
  test('both released levels are gated', () {
    // If a level can ship without a config, this whole suite is optional.
    expect(kLevelGates.map((g) => g.levelId), containsAll(['a1', 'a2']));
  });

  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('the finished list is not empty and names real, distinct units', () {
        expect(gate.finishedUnitIds, isNotEmpty);
        expect(
          gate.finishedUnitIds.toSet().length,
          gate.finishedUnitIds.length,
          reason: 'duplicate id in ${gate.levelId} finished list',
        );
        final inBundle = {for (final u in gate.bundle().units) u.id};
        expect(inBundle.containsAll(gate.finishedUnitIds), isTrue);
      });

      test('every declared exception names a unit that exists and says why', () {
        // A stale exception is worse than none: it silently excuses a unit
        // that no longer needs excusing, and nothing would ever tell us.
        final unitIds = gate.finishedUnitIds.toSet();
        for (final entry in {
          ...gate.unitShapeExceptions,
          ...gate.skillBalanceExceptions,
        }.entries) {
          expect(
            unitIds,
            contains(entry.key),
            reason: '${gate.levelId} excepts ${entry.key}, which is not a '
                'finished unit',
          );
        }
        for (final e in [
          ...gate.unitShapeExceptions.values,
          ...gate.skillBalanceExceptions.values,
        ]) {
          expect(
            e.reason.trim(),
            isNotEmpty,
            reason: 'an exception with no reason is a skip wearing a hat',
          );
        }
      });

      test('the band tiers cover every finished unit', () {
        // Without this, adding U13 to a level would silently reuse the last
        // tier's numbers instead of failing.
        for (final unit in gate.finishedUnits()) {
          expect(
            () => gate.bandsFor(unit.id),
            returnsNormally,
            reason: 'no length band covers ${unit.id}',
          );
        }
      });

      test('the capstones the config names exist in the bundle', () {
        final bundle = gate.bundle();
        expect(bundle.finalMission.id, gate.finalMissionId);
        expect(bundle.finalAssessment.id, gate.finalAssessmentId);
      });
    });
  }

  test('no id is shared between any two levels', () {
    final seen = <String, String>{};
    for (final gate in kLevelGates) {
      for (final u in gate.bundle().units) {
        for (final id in [
          u.id,
          for (final l in u.lessons) ...[
            l.id,
            for (final a in l.activities) a.id,
          ],
        ]) {
          final owner = seen[id];
          expect(
            owner,
            isNull,
            reason: '$id belongs to both $owner and ${gate.levelId}',
          );
          seen[id] = gate.levelId;
        }
      }
    }
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/content/levels/level_config_test.dart`
Expected: FAIL — `level_gate_config.dart` does not exist.

- [ ] **Step 3: Write the config**

A2's numbers are copied verbatim from the existing gates — `a2_structure_test.dart` for the shape, `a2_design_limits_test.dart` for the balance, bands and vocabulary floor, `a2_capstone_checks.dart` for the pass mark. Read each one and transcribe; do not re-derive them from the spec, because the gates are what A2 actually passes today and this task must not change that.

```dart
// test/content/levels/level_gate_config.dart
import 'dart:io';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// A rule a level is held to at a different value, with the reason written
/// down. Deliberately NOT a skip: an excepted unit is still checked, just
/// against its own numbers, so drifting further still fails.
class DeclaredException<T> {
  const DeclaredException({required this.value, required this.reason});

  final T value;
  final String reason;
}

class Range {
  const Range(this.min, this.max);
  const Range.exactly(int n) : min = n, max = n;

  final int min;
  final int max;

  bool contains(int n) => n >= min && n <= max;
  @override
  String toString() => min == max ? '$min' : '$min-$max';
}

class UnitShape {
  const UnitShape({
    required this.lessons,
    required this.activities,
    required this.encounter,
    required this.practice,
    required this.mastery,
  });

  final int lessons;
  final int activities;
  final int encounter;
  final int practice;
  final int mastery;
}

class SkillBalance {
  const SkillBalance({
    required this.listening,
    required this.reading,
    required this.speaking,
    required this.writing,
    required this.mediation,
  });

  final Range listening;
  final Range reading;

  /// Spoken production and spoken interaction together.
  final Range speaking;
  final Range writing;
  final Range mediation;
}

/// Word-count bands for units up to [throughUnitIndex], inclusive. Texts
/// climb across a level, so a level has several tiers.
class LengthBandTier {
  const LengthBandTier({
    required this.throughUnitIndex,
    required this.listening,
    required this.reading,
    required this.writing,
  });

  final int throughUnitIndex;
  final Range listening;
  final Range reading;
  final Range writing;
}

/// How a level tags its activities with Can-Do objectives.
///
/// [perActivitySkill]: each activity carries objectives of its own skill's
/// category. [lessonWide]: activities carry their lesson's whole list, so
/// the category check runs at lesson granularity instead (see
/// `level_design_limits_test.dart`) — a different granularity, not a
/// weaker rule.
enum CanDoTagging { perActivitySkill, lessonWide }

class LevelGateConfig {
  const LevelGateConfig({
    required this.levelId,
    required this.bundleAssetPath,
    required this.courseId,
    required this.prerequisiteLevelId,
    required this.finishedUnitIds,
    required this.unitShape,
    required this.skillBalance,
    required this.bandTiers,
    required this.minimumNewSensesPerUnit,
    required this.canDoTagging,
    required this.finalMissionId,
    required this.finalAssessmentId,
    required this.capstonePassMark,
    this.unitShapeExceptions = const {},
    this.skillBalanceExceptions = const {},
  });

  final String levelId;
  final String bundleAssetPath;
  final String courseId;
  final String? prerequisiteLevelId;

  /// The units that claim to be finished content. A unit joins in the batch
  /// that authors it — never before — and a level cannot be marked
  /// available until this is every unit in its bundle.
  final List<String> finishedUnitIds;

  final UnitShape unitShape;
  final Map<String, DeclaredException<UnitShape>> unitShapeExceptions;
  final SkillBalance skillBalance;
  final Map<String, DeclaredException<SkillBalance>> skillBalanceExceptions;
  final List<LengthBandTier> bandTiers;
  final int minimumNewSensesPerUnit;
  final CanDoTagging canDoTagging;
  final String finalMissionId;
  final String finalAssessmentId;
  final double capstonePassMark;

  CourseBundle bundle() =>
      CourseBundleParser.parse(File(bundleAssetPath).readAsStringSync());

  List<Unit> finishedUnits() {
    if (finishedUnitIds.isEmpty) {
      throw StateError(
        '$levelId has an empty finished list: every gate would pass while '
        'asserting nothing. Removing the last unit is never the right way '
        'to make this suite green.',
      );
    }
    final byId = {for (final u in bundle().units) u.id: u};
    return [
      for (final id in finishedUnitIds)
        byId[id] ??
            (throw StateError(
              '$levelId names $id, which its bundle does not contain',
            )),
    ];
  }

  UnitShape shapeFor(String unitId) =>
      unitShapeExceptions[unitId]?.value ?? unitShape;

  SkillBalance balanceFor(String unitId) =>
      skillBalanceExceptions[unitId]?.value ?? skillBalance;

  /// The reason this unit is excepted, or null. Gates put it in their
  /// failure messages so a reader never has to hunt for why.
  String? exceptionReason(String unitId) =>
      unitShapeExceptions[unitId]?.reason ??
      skillBalanceExceptions[unitId]?.reason;

  LengthBandTier bandsFor(String unitId) {
    final n = int.parse(unitId.split('-U').last);
    for (final tier in bandTiers) {
      if (n <= tier.throughUnitIndex) return tier;
    }
    throw StateError(
      '$levelId has no length band covering $unitId; add a tier rather than '
      'letting a new unit inherit the last one by accident',
    );
  }
}

Iterable<Activity> activitiesOf(Unit unit) =>
    unit.lessons.expand((l) => l.activities);

const _a2 = LevelGateConfig(
  levelId: 'a2',
  bundleAssetPath: 'assets/content/en/A2/a2-course-bundle.json',
  courseId: 'EN-A2-V1',
  prerequisiteLevelId: 'a1',
  finishedUnitIds: [
    'A2-U1',
    'A2-U2',
    'A2-U3',
    'A2-U4',
    'A2-U5',
    'A2-U6',
    'A2-U7',
    'A2-U8',
    'A2-U9',
    'A2-U10',
    'A2-U11',
    'A2-U12',
  ],
  unitShape: UnitShape(
    lessons: 7,
    activities: 36,
    encounter: 6,
    practice: 12,
    mastery: 18,
  ),
  skillBalance: SkillBalance(
    listening: Range(10, 36),
    reading: Range(0, 12),
    speaking: Range(6, 8),
    writing: Range.exactly(3),
    mediation: Range.exactly(2),
  ),
  bandTiers: [
    LengthBandTier(
      throughUnitIndex: 4,
      listening: Range(30, 60),
      reading: Range(60, 100),
      writing: Range(55, 75),
    ),
    LengthBandTier(
      throughUnitIndex: 8,
      listening: Range(50, 90),
      reading: Range(90, 140),
      writing: Range(65, 85),
    ),
    LengthBandTier(
      throughUnitIndex: 12,
      listening: Range(70, 120),
      reading: Range(120, 180),
      writing: Range(75, 100),
    ),
  ],
  minimumNewSensesPerUnit: 30,
  canDoTagging: CanDoTagging.perActivitySkill,
  finalMissionId: 'A2-FINAL-MISSION',
  finalAssessmentId: 'A2-FINAL-ASSESSMENT',
  capstonePassMark: 0.6,
);

const kLevelGates = <LevelGateConfig>[_a2];
```

A1's config is added in Task 7, not here — the port must be proven not to change A2 before a second level is introduced.

- [ ] **Step 4: Run it and watch it pass**

Run: `flutter test test/content/levels/level_config_test.dart`
Expected: the "both released levels are gated" test FAILS (A1 is not in the list yet — that is Task 7); everything else passes. Mark this known-failing in the ledger and carry it forward; it turns green in Task 7 and is the signal that Task 7 is done.

- [ ] **Step 5: Commit**

```bash
git add test/content/levels/
git commit -m "test: put a level's gate numbers in one place"
```

---

### Task 2: Port the structure and masterable gates

**Files:**
- Create: `test/content/levels/level_structure_test.dart` (from `a2_structure_test.dart` + `a2_bundle_loads_test.dart`)
- Create: `test/content/levels/level_masterable_test.dart` (from `a2_masterable_test.dart`)

**Interfaces:**
- Consumes: everything Task 1 produced.

**The transformation, applied to every gate file in Tasks 2-5.** It is mechanical, and it is the same each time:

1. Wrap the file's `main()` body in `for (final gate in kLevelGates) { group(gate.levelId.toUpperCase(), () { ... }); }`.
2. Replace `finishedA2Units()` with `gate.finishedUnits()`, `loadA2Bundle()` with `gate.bundle()`, and `loadA1Bundle()` with the prerequisite level's bundle looked up through `kLevelGates` by `gate.prerequisiteLevelId` (null means no prerequisite — the reference-resolution gate then checks the level's own registries only).
3. Replace every hardcoded number with the config field that holds it: `7` → `gate.shapeFor(unit.id).lessons`, `36` → `.activities`, `6/12/18` → `.encounter/.practice/.mastery`, the skill counts → `gate.balanceFor(unit.id)`, `_bandsFor(...)` → `gate.bandsFor(...)`, `30` → `gate.minimumNewSensesPerUnit`, `'A2-FINAL-MISSION'` → `gate.finalMissionId`, `0.6` → `gate.capstonePassMark`.
4. Put `gate.levelId` and, when the unit is excepted, `gate.exceptionReason(unit.id)` into every `reason:` string, so a failure says which level and why that unit has its own numbers.
5. Change nothing else. Not a threshold, not a predicate, not a message's meaning.

- [ ] **Step 1: Port `level_structure_test.dart`**

Four tests from `a2_structure_test.dart` (finished list not empty; unit shape; reference resolution; no shared ids) and two from `a2_bundle_loads_test.dart` (the bundle parses/indexes/resolves; every unit counts toward its level). Two adjustments beyond the mechanical transformation, both of which must be stated in the commit message:

- The hardcoded `hasLength(12)` / `hasLength(84)` / `finalMission.id` assertions in `a2_bundle_loads_test.dart` become `gate.finishedUnitIds.length`, the sum of the units' lesson counts, and `gate.finalMissionId`.
- "no id is shared between A1 and A2" already moved to `level_config_test.dart` in Task 1 as an all-pairs check. Delete it here rather than keeping two copies.

- [ ] **Step 2: Port `level_masterable_test.dart`**

Four tests. Three port mechanically. The fourth — the release rule — needs care:

- It reads `kLevelCatalog.firstWhere((e) => e.levelId == 'a2')`; that becomes `gate.levelId`.
- It asserts `File('test/content/a2_capstones_test.dart').existsSync()`. **That path is about to stop existing.** Point it at `test/content/levels/level_capstones_test.dart` in Task 5, and until then leave the assertion pointing at the file that exists. Getting this wrong makes the release rule pass while the capstone suite is gone, which is the exact failure the assertion was added to prevent.

- [ ] **Step 3: Run both**

```bash
flutter test test/content/levels/
```
Expected: PASS for the A2 group. Compare against the pre-port run of `flutter test test/content/a2_structure_test.dart test/content/a2_bundle_loads_test.dart test/content/a2_masterable_test.dart` and confirm the same rules pass. Record both counts in your report.

- [ ] **Step 4: Commit**

```bash
git add test/content/levels/
git commit -m "test: run the structure and mastery gates from a level config"
```

---

### Task 3: Port the answerable and bilingual gates

**Files:**
- Create: `test/content/levels/level_answerable_test.dart` (10 tests from `a2_answerable_test.dart`)
- Create: `test/content/levels/level_bilingual_test.dart` (8 tests from `a2_bilingual_test.dart`)

Apply the transformation from Task 2. Two things to watch, both of which were defects in this suite's own history:

- `a2_answerable_test.dart`'s last test is "no A1 sense is re-registered by a finished unit" — it hardcodes A1 as the earlier level. That becomes the prerequisite level from the config, and it does not run when `prerequisiteLevelId` is null.
- Several of these gates read `a.raw[...]` directly. Where a parsed accessor exists for the same data, the gate must use the accessor — reading the raw map was the source of a real defect in this suite (a gate read `raw['partnerTurns']` while the app read a filtering parsed accessor, so the gate passed on turns the app dropped). **Do not fix any such case in this task**: note it in your report, and it is triaged in Task 8. This task changes no rule.

- [ ] **Step 1: Port both files**
- [ ] **Step 2: Run, compare counts against the pre-port files, record both in the report**
- [ ] **Step 3: Commit**

```bash
git add test/content/levels/
git commit -m "test: run the answerable and bilingual gates from a level config"
```

---

### Task 4: Port the design-limits gate

**Files:**
- Create: `test/content/levels/level_design_limits_test.dart` (12 tests from `a2_design_limits_test.dart`)

This is the file the config was shaped around, and the one place where a level genuinely differs in kind rather than in number: Can-Do tagging.

- [ ] **Step 1: Port the eleven numeric gates**

Mechanically, per Task 2. Skill balance reads `gate.balanceFor(unit.id)` and each of the five skills is checked with `Range.contains`, with the range's `toString()` in the failure message.

- [ ] **Step 2: Make the Can-Do category gate level-aware**

The existing test asserts each activity's objectives carry its own skill's category (`.LISTENING.`, `.READING.`, …), with `.ACTION.` exempt. Under `CanDoTagging.perActivitySkill` it runs exactly as it does today. Under `CanDoTagging.lessonWide` it is replaced by two checks at lesson granularity — not removed, and not relaxed to nothing:

```dart
test("an activity's canDo objectives match the skill it evidences", () {
  const categoryBySkill = {
    Skill.listening: 'LISTENING',
    Skill.reading: 'READING',
    Skill.writing: 'WRITING',
    Skill.spokenProduction: 'PRODUCTION',
    Skill.spokenInteraction: 'INTERACTION',
    Skill.mediation: 'MEDIATION',
  };
  for (final unit in gate.finishedUnits()) {
    for (final lesson in unit.lessons) {
      for (final a in lesson.activities) {
        if (gate.canDoTagging == CanDoTagging.perActivitySkill) {
          final expected = categoryBySkill[a.skill]!;
          for (final objective in a.canDo) {
            // A mission's ACTION.* objective accepts evidence from any skill.
            if (objective.contains('.ACTION.')) continue;
            expect(
              objective,
              contains('.$expected.'),
              reason: '${gate.levelId} ${a.id} (${a.skill}) claims $objective',
            );
          }
        } else {
          // This level tags activities with their lesson's whole list, so
          // an activity's objectives cannot be matched to its own skill.
          // The equivalent check at lesson granularity: an activity may
          // only claim what its lesson declares, and every skill the
          // lesson's activities evidence must have an objective of its
          // category in that list. A mis-categorised lesson still fails.
          expect(
            lesson.canDo,
            containsAll(a.canDo),
            reason: '${gate.levelId} ${a.id} claims an objective its lesson '
                '${lesson.id} does not declare',
          );
        }
      }
      if (gate.canDoTagging == CanDoTagging.lessonWide) {
        final categories = {
          for (final objective in lesson.canDo)
            for (final entry in categoryBySkill.entries)
              if (objective.contains('.${entry.value}.')) entry.value,
        };
        for (final skill in {for (final a in lesson.activities) a.skill}) {
          expect(
            categories,
            contains(categoryBySkill[skill]!),
            reason: '${gate.levelId} ${lesson.id} has ${skill.name} '
                'activities but declares no ${categoryBySkill[skill]} '
                'objective — a learner evidences nothing by doing them',
          );
        }
      }
    }
  }
});
```

- [ ] **Step 3: Prove the lesson-wide branch still catches a mis-tag**

Once A1 is in the config (Task 7), come back and mutate one A1 lesson: change its `canDo` list so a lesson with writing activities declares no `WRITING` objective. Confirm the gate fails naming that lesson, then revert. Record the message. **A branch nobody has watched fail is a branch nobody knows works** — and this branch exists specifically to avoid weakening a check, so it has to earn that claim. Note this step as carried forward in the ledger; it is completed as part of Task 7.

- [ ] **Step 4: Run, compare counts, commit**

```bash
git add test/content/levels/
git commit -m "test: run the design-limit gates from a level config"
```

---

### Task 5: Port the capstone gates and retire the A2 files

**Files:**
- Create: `test/content/levels/level_capstone_checks.dart`, `test/content/levels/level_capstones_test.dart`
- Delete: all seven `test/content/a2_*_test.dart` plus `a2_finished_units.dart` and `a2_capstone_checks.dart`

- [ ] **Step 1: Port the capstone checks**

`a2_capstone_checks.dart` is 537 lines of violation-collecting functions. Each takes a `CourseBundle`; they now take `(CourseBundle bundle, LevelGateConfig gate)` so `capstonePassMarkViolations` reads `gate.capstonePassMark` and the structure checks read `gate.finalMissionId`/`finalAssessmentId`. `allCapstoneViolations` gains the same parameter. Nothing else changes: same rules, same messages.

- [ ] **Step 2: Port the eight capstone tests**, per Task 2's transformation.

- [ ] **Step 3: Point the release rule at the new file**

In `level_masterable_test.dart`, the release rule's file-existence assertion now names `test/content/levels/level_capstones_test.dart`. Verify by hand that the path is exactly right — a typo here makes the assertion pass-by-absence forever.

- [ ] **Step 4: Count before deleting**

```bash
flutter test test/content/ 2>&1 | tail -5
```

Record the total. Then delete the nine `a2_*` files and re-run. The A2 rules in the new suite must cover every rule the old files held: walk the old files' test names one by one against the new suite's and account for each. Any rule you cannot find a home for is a port defect, not a rule to drop.

- [ ] **Step 5: Full suite, then commit**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

```bash
git add -A test/content/
git commit -m "test: one gate suite for every level, not one written for A2"
```

---

### Task 6: Add A1 to the suite, and see what it says

**Files:**
- Modify: `test/content/levels/level_gate_config.dart`

**This task deliberately ends red.** Its deliverable is a triage report, not a green suite.

- [ ] **Step 1: Add A1's config**

Fill it from A1's own bundle and its existing tests — `a1_content_quality_test.dart`, the per-unit mastery regressions, and the bundle itself. The two decided exceptions go in now:

```dart
const _a1 = LevelGateConfig(
  levelId: 'a1',
  bundleAssetPath: 'assets/content/en/A1/a1-course-bundle.json',
  courseId: 'EN-A1-V2', // verify against the bundle before committing
  prerequisiteLevelId: null,
  finishedUnitIds: [
    'A1-U0',
    'A1-U1',
    'A1-U2',
    'A1-U3',
    'A1-U4',
    'A1-U5',
    'A1-U6',
    'A1-U7',
    'A1-U8',
    'A1-U9',
    'A1-U10',
    'A1-U11',
    'A1-U12',
  ],
  unitShape: UnitShape(
    lessons: 7,
    activities: 36,
    encounter: 6,
    practice: 12,
    mastery: 18,
  ),
  unitShapeExceptions: {
    'A1-U0': DeclaredException(
      value: UnitShape(
        lessons: 5,
        activities: 20,
        encounter: 2,
        practice: 5,
        mastery: 13,
      ),
      reason:
          'A1-U0 is an onboarding unit, deliberately shorter than a '
          'teaching unit. Re-cutting it would move published activity ids, '
          'which the id-stability guard forbids.',
    ),
    'A1-U1': DeclaredException(
      value: UnitShape(
        lessons: 7,
        activities: 30,
        encounter: 5,
        practice: 7,
        mastery: 18,
      ),
      reason:
          'A1-U1 was authored before the 6/12/18 shape settled; U2-U12 all '
          'follow it. Re-cutting U1 would move published activity ids, '
          'which the id-stability guard forbids.',
    ),
  },
  // …balance, bandTiers, minimumNewSensesPerUnit filled from A1's content
  canDoTagging: CanDoTagging.lessonWide,
  finalMissionId: 'A1-FINAL-MISSION',
  finalAssessmentId: 'A1-FINAL-ASSESSMENT',
  capstonePassMark: 0.6,
);

const kLevelGates = <LevelGateConfig>[_a1, _a2];
```

Every value marked "filled from A1's content" must be a real number you verified against the bundle, and **the numbers are the level's design, not a description of what A1 happens to contain**. Do not compute a band from A1's longest text and call it the band — that makes the gate a tautology. Set each from A1's design intent (its unit plan in `reference/a1-modular-course/`, or A2's tier shape scaled down), then let Step 2 report what fails.

- [ ] **Step 2: Run it and write the triage report**

```bash
flutter test test/content/levels/ 2>&1 | tee <workspace>/a1-triage.txt
```

Write `<workspace>/a1-triage.md`: one row per distinct failure, with the gate, the units or activities it names, how many, and one line on what is actually wrong. Group by cause, not by test — twelve units failing one band is one row, not twelve.

- [ ] **Step 3: Commit the config, red suite and all**

```bash
git add test/content/levels/level_gate_config.dart
git commit -m "test: hold A1 to the same gates as A2"
```

Say in the commit message that the suite is red and that the next commits resolve it. A red commit that announces itself is honest; a green one that got there by lowering a bar is not.

---

### Task 7: Triage every A1 failure

**Files:** varies by finding — `test/content/levels/level_gate_config.dart` and/or `assets/content/en/A1/a1-course-bundle.json`.

**The decision procedure.** Every failure ends as exactly one of three things, and the choice is recorded:

1. **A declared exception**, when A1 is legitimately different and changing it would move published ids or re-cut shipped content. Goes in the config with a reason written in the same voice as the two above: what is different, and why it stays that way.
2. **An A1 content fix**, when the gate found a real defect — a listening activity with no transcript, a closed question with no correct answer, an English prompt with no Arabic. Fix the content, in its own commit, naming the gate that found it. Additive only: the id-stability guard forbids removing an activity or changing its mode, so a broken activity is repaired in place, never deleted.
3. **A config difference**, when the rule is right but A1's number is legitimately its own — shorter texts at a lower CEFR level, a lower vocabulary floor. Set A1's value and say in the commit why that number is A1's design.

**What is never an outcome:** lowering A2's number, widening a shared range until both pass, adding a skip, or removing a unit from `finishedUnitIds`. If a failure seems to need one of those, it is a finding to report, not a change to make.

- [ ] **Step 1: Work the report row by row**, committing per cause so each is reviewable alone.

- [ ] **Step 2: Complete Task 4 Step 3** — mutate an A1 lesson's `canDo` so a lesson with writing activities declares no `WRITING` objective, confirm the lesson-wide branch fails naming it, revert, record the message.

- [ ] **Step 3: Mutation-test the exceptions**

Change A1-U0's lesson count in the bundle from 5 to 4 and confirm the shape gate fails naming A1-U0 **and printing its exception reason**. Revert. An exception that stops checking is the failure mode this whole design exists to avoid.

- [ ] **Step 4: Green suite, full run**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Report the counts and, separately, a list of every A1 content defect the gates found — with what each one would have done to a learner. That list is the answer to "was this worth doing".

---

### Task 8: Documents

**Files:** `docs/TESTING.md`, `docs/CONVENTIONS.md`, `CLAUDE.md`

Derive the full list from CLAUDE.md's Definition-of-done table, and give one line of reasoning in your report for each row you rule non-applicable.

- [ ] **Step 1: TESTING.md**

Describe the suite as it now is: `test/content/levels/` holds the gates, `level_gate_config.dart` holds each level's numbers, a level joins by adding a config, and an exception is a value with a reason rather than a skip. Name the two declared A1 exceptions and why they stand.

- [ ] **Step 2: CLAUDE.md**

Its header paragraph says A2 is gated by `test/content/a2_*`, 7 files and 47 tests. That is about to be false. Replace it with what is true after this plan, and keep it one sentence.

- [ ] **Step 3: Commit**

```bash
git add docs/ CLAUDE.md
git commit -m "docs: describe the gate suite as one suite over every level"
```

Bump each edited doc's **Last verified** line to the day of the edit, naming the change and the branch, in that file's own style.

---

## Self-review notes

- **Exceptions are values, not skips.** There is no boolean in the config that turns a check off, which is what keeps "hold A1 to the same standard" from decaying into "list what A1 is allowed to fail".
- **Task 6 ends red on purpose.** Separating "hold A1 to the gates" from "resolve what that found" means the diff that introduces the standard and the diff that changes A1 are reviewable apart.
- **Task 5 Step 4 counts before deleting.** Porting 47 tests across seven files and losing two of them is the likeliest silent failure here, and a count plus a name-by-name walk is what catches it.
- **The release rule's file-path assertion is called out twice** (Task 2 Step 2, Task 5 Step 3) because it is a string literal pointing at a file this plan deletes, and a wrong string there fails open.
- **The band-setting instruction in Task 6 Step 1 is deliberate.** Deriving a band from the content it is supposed to constrain produces a gate that can never fail, which is the most common way a suite like this turns into decoration.

## Outcome (2026-09-22)

Task 6 ran red as planned: 19 A1 failures. The product owner chose to fix everything rather than ratchet, so Task 7's third outcome (config difference) covered four rules and its second (content fix) covered the rest — roughly 290 items, all additive, no id moved. Eight further failures turned out to be the gate's fault, each the cruder-key-than-the-rule-means defect; they are listed in TESTING.md. Two of the exceptions this plan anticipated (U0/U1 shape) stand; the lesson-wide Can-Do characterisation was wrong — A1's tags are per-activity but cross categories — and became a unit-level check instead; the skill balance stands as A1's own numbers. `wordGuideMustEqualBand`, `sourceCardWords`, capstone bands and `kLevelBundlePaths` were added to the config beyond what Task 1 listed. Final: 106 tests over both levels, none failing, no A2 outcome changed.
