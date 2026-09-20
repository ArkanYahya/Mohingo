# A2 Step 4 — Content Quality Gates and the Pilot Unit (A2-U1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn "is A2 ready?" from an opinion into a test run, and author A2-U1 to the standard those tests encode.

**Architecture:** A suite of content tests under `test/content/a2_*` runs over a **finished-units list** that grows with each batch. The list starts holding `A2-U1` only, so every gate fails against today's imported content and the pilot's job is to make them pass. The unit is then authored in place in `assets/content/en/A2/a2-course-bundle.json` — conversations, texts, source cards, partner turns, vocabulary — against an activity map fixed in this plan, so the unit is in skill balance by construction rather than by luck.

**Tech Stack:** Dart/Flutter, `flutter_test`; the content layer's own parser (`CourseBundleParser`) and models (`lib/content/models/`); the bundle is plain JSON.

**Spec:** `docs/superpowers/specs/2026-09-19-a2-level-design.md` (Designs 1, 2 and 5)

## Global Constraints

- All user-facing copy is bilingual: **Arabic written natively, never word-for-word translation from the English**. This is a CLAUDE.md non-negotiable, and 38 dialogue lines currently have no Arabic at all.
- The app works fully offline; this plan adds no dependency and no network call.
- Unit shape is fixed: **7 lessons, 36 activities, 6 `encounter` / 12 `practice` / 18 `mastery`**.
- **U1 length bands (the U1–U4 column):** listening 30–60 words; lesson `readingText` 60–100 words; `wordGuide` 55–75; single-question notices (`sourceText`/`sourceCard`) 15–60 words.
- **Skill balance per unit:** listening ≥10, reading ≤12, speaking (interaction + production) 6–8, writing 3, mediation 2.
- No prompt text repeated more than 3 times per unit; at most **one** English↔Arabic matching activity per unit.
- Unit mastery threshold stays 0.75; Final Assessment / Final Mission pass marks are 0.6 (not this plan's concern, but do not "fix" them).
- IDs are stable: **never renumber or rename an existing activity, lesson or unit id.** Learner progress and the objective map key off them.
- A1 grammar/lexicon/chunks are **referenced by id, never re-registered** in A2.
- No present perfect in U1. Per the spec's grammar map it enters at U8 (experience) and U12 (*just/already/yet*). U1 is present simple vs continuous, state verbs, and follow-up questions (*How long / How often*).

---

## What the audit found (2026-09-20, against the shipped bundle)

The imported reference is structurally valid but pedagogically unbuilt. Verified counts:

| Area | Spec | Bundle today |
|---|---|---|
| `encounter.dialogue` | 2–3 speakers, 4–8 lines, Arabic every line | **1 line, 1 speaker** in 72 lessons; **0 lines** in 12; **38 lines have no Arabic** |
| `sourceCard` on mediation | every mediation task | **0 of 24** |
| `partnerTurns` on speak | interaction tasks carry them | **0 of 96** |
| lesson `readingText` (L6 model text) | one per unit | **0 in the whole bundle** |
| Listening per unit | ≥10 | 5–7 |
| Reading per unit | ≤12 | 19–21 |
| Listening text, U1 | 30–60 words | 13–23 |
| `wordGuide`, U1 | 55–75 | `[60,90]`, `[80,110]` |
| Lexicon senses per unit | ~35 | 18 |
| `evaluation` on mastery speak/write | structured `keywordChecklist` | the **retired legacy shape** — an opaque list of rubric names |
| Activity `canDo` | only its own skill's objectives | listening items also claim `PRODUCTION.*` objectives |

The legacy evaluation is worth spelling out, because "it has an
`evaluation`" reads as fine until you look at it:

```json
"evaluation": ["taskCompletion", "intelligibility", "appropriateLanguage", "accuracy"]
```

Nothing grades that. A1 was migrated off it onto structured specs
(`keywordChecklist` with `requiredGroups`, `minGroupsMatched`, and
`onlineRefinement: "grammarCheck"` for open paragraphs — see
`A1-U2-L4-A05` for a real one). Every A2 mastery speak/write task needs the
structured form, authored from the keywords that task actually expects.

Already sound, do not "fix": every required objective has ≥2 mastery-mode evidences in all 12 units; every activity has a `canDo`, an Arabic prompt, and its type's answer carrier.

---

## File structure

| File | Responsibility |
|---|---|
| `test/content/a2_finished_units.dart` | The single list of units claimed finished, plus the shared bundle/parse helpers every a2 test uses. One place to edit per batch. |
| `test/content/a2_structure_test.dart` | Shape and references: lesson/activity counts, mode split, id uniqueness across A1+A2, every grammar/lexicon/chunk reference resolves. |
| `test/content/a2_bilingual_test.dart` | Arabic present and well-typed everywhere; no Arabic script inside English fields. |
| `test/content/a2_answerable_test.dart` | Nothing asks for information the learner was never given. |
| `test/content/a2_design_limits_test.dart` | Skill balance, length bands, `wordGuide`, prompt repetition, matching cap, `canDo` category matches skill, dialogue shape. |
| `test/content/a2_masterable_test.dart` | Answering every `mastery` item correctly masters the unit; and the release rule for `kLevelCatalog`. |
| `assets/content/en/A2/a2-course-bundle.json` | The content itself — U1's seven lessons, its registries, its source material. |

---

## The U1 activity map (fixed here so the unit balances by construction)

36 activities. Keep every existing id; change type/mode/skill to match this table.

| Lesson | Activity | Mode | Skill | What it is |
|---|---|---|---|---|
| L1–L5 | `A01` | encounter | listening | Gist question on that lesson's conversation (not a copy of its text) |
| L1–L5 | `A02` | practice | reading | Form: gap or order on the lesson's target structure |
| L1–L5 | `A03` | practice | reading | Meaning: question→answer, sentence halves, or choose the right form |
| L1–L5 | `A04` | mastery | listening (L1,L2,L3,L5) / reading (L4) | Receptive item on **new** input — a second short recording or text, never the conversation again |
| L1 | `A05` | mastery | spokenProduction | Speaking task with `evaluation` |
| L2 | `A05` | mastery | spokenInteraction | Speaking task with `partnerTurns` + `evaluation` |
| L3 | `A05` | mastery | spokenProduction | Speaking task with `evaluation` |
| L4 | `A05` | mastery | writing | Short written task, `wordGuide: [55, 75]`, `evaluation` |
| L5 | `A05` | mastery | spokenInteraction | Speaking task with `partnerTurns` + `evaluation` |
| L6 | `A01` | encounter | reading | Gist question on the lesson's `readingText` |
| L6 | `A02` | practice | reading | Detail question on the same `readingText` |
| L6 | `A03` | mastery | listening | New recording on the same topic |
| L6 | `A04` | mastery | writing | The learner writes their own, `wordGuide: [55, 75]`, `evaluation` |
| L6 | `A05` | mastery | mediation | Relay from a `sourceCard` |
| L7 | `A01` | practice | listening | Mission input: a short recording |
| L7 | `A02` | mastery | spokenInteraction | `partnerTurns` + `evaluation` |
| L7 | `A03` | mastery | spokenProduction | `evaluation` |
| L7 | `A04` | mastery | writing | `wordGuide: [55, 75]`, `evaluation` |
| L7 | `A05` | mastery | mediation | `sourceCard` + `evaluation` |
| L7 | `A06` | mastery | reading | Mission notice or message |

Totals: listening 11, reading 12, spokenProduction 4, spokenInteraction 4, writing 3, mediation 2 = 36. Modes: 6 encounter, 12 practice, 18 mastery.

---

### Task 1: The finished-units list, shared helpers, and the structure gate

**Files:**
- Create: `test/content/a2_finished_units.dart`
- Create: `test/content/a2_structure_test.dart`

**Interfaces:**
- Produces: `const a2FinishedUnitIds = <String>['A2-U1'];`, `CourseBundle loadA2Bundle()`, `CourseBundle loadA1Bundle()`, `List<Unit> finishedA2Units()`, `Iterable<Activity> activitiesOf(Unit unit)`.

- [ ] **Step 1: Write the helper file**

Import paths, verified against the code — use exactly these. `Skill` and
`ActivityMode` live in `domain_definitions.dart`, not in `activity.dart`;
`CourseBundle` lives in `course_bundle.dart`, not in
`curriculum_structure.dart`.

```dart
// test/content/a2_finished_units.dart
import 'dart:io';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// The A2 units that claim to be finished content, not imported skeleton.
///
/// Every `test/content/a2_*` gate runs over exactly this list. A unit joins
/// it in the batch that authors it — never before — and A2 cannot be marked
/// available in the catalogue until all twelve are here (see
/// `a2_masterable_test.dart`'s release rule).
const a2FinishedUnitIds = <String>['A2-U1'];

CourseBundle loadA2Bundle() => CourseBundleParser.parse(
  File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
);

CourseBundle loadA1Bundle() => CourseBundleParser.parse(
  File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
);

List<Unit> finishedA2Units() {
  final byId = {for (final u in loadA2Bundle().units) u.id: u};
  return [
    for (final id in a2FinishedUnitIds)
      byId[id] ??
          (throw StateError('a2FinishedUnitIds names $id, which the bundle '
              'does not contain')),
  ];
}

Iterable<Activity> activitiesOf(Unit unit) =>
    unit.lessons.expand((l) => l.activities);
```

- [ ] **Step 2: Write the failing structure test**

```dart
// test/content/a2_structure_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';

import 'a2_finished_units.dart';

void main() {
  test('the finished list is not empty', () {
    // Every other gate in this directory iterates that list. An empty list
    // would make all of them pass while asserting nothing.
    expect(a2FinishedUnitIds, isNotEmpty);
  });

  test('each finished unit has 7 lessons and 36 activities, split 6/12/18', () {
    for (final unit in finishedA2Units()) {
      expect(unit.lessons.length, 7, reason: '${unit.id} lessons');
      final acts = activitiesOf(unit).toList();
      expect(acts.length, 36, reason: '${unit.id} activities');
      int count(ActivityMode m) => acts.where((a) => a.mode == m).length;
      expect(count(ActivityMode.encounter), 6, reason: '${unit.id} encounter');
      expect(count(ActivityMode.practice), 12, reason: '${unit.id} practice');
      expect(count(ActivityMode.mastery), 18, reason: '${unit.id} mastery');
    }
  });

  test('every grammar, lexicon and chunk reference resolves in A2 or A1', () {
    final a2 = loadA2Bundle();
    final a1 = loadA1Bundle();
    final known = {
      ...a2.grammar.map((g) => g.id),
      ...a2.lexicon.map((l) => l.id),
      ...a2.chunks.map((c) => c.id),
      ...a1.grammar.map((g) => g.id),
      ...a1.lexicon.map((l) => l.id),
      ...a1.chunks.map((c) => c.id),
    };
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final id in [...lesson.grammar, ...lesson.lexicon, ...lesson.chunks]) {
          expect(known, contains(id), reason: '${lesson.id} references $id');
        }
      }
    }
  });

  test('no id is shared between A1 and A2', () {
    Set<String> ids(CourseBundle b) => {
      for (final u in b.units) ...[
        u.id,
        for (final l in u.lessons) ...[l.id, for (final a in l.activities) a.id],
      ],
    };
    expect(ids(loadA1Bundle()).intersection(ids(loadA2Bundle())), isEmpty);
  });
}
```

This file needs `import 'package:mohingo/content/models/course_bundle.dart';`
and `import 'package:mohingo/content/models/domain_definitions.dart';` (for
`ActivityMode`) alongside the helper import.

- [ ] **Step 3: Run it and watch it fail**

Run: `flutter test test/content/a2_structure_test.dart`
Expected: the 7/36/6-12-18 test FAILS — U1 has 36 activities but the mode split is not 6/12/18 today. Record the actual split in your report.

- [ ] **Step 4: Commit the gates only**

The content fix comes in Tasks 7–11. Commit the failing gates now so the rest of the plan has something to turn green.

```bash
git add test/content/a2_finished_units.dart test/content/a2_structure_test.dart
git commit -m "test: gate A2 units on shape, references and id uniqueness"
```

---

### Task 2: The bilingual gate

**Files:**
- Create: `test/content/a2_bilingual_test.dart`

**Interfaces:**
- Consumes: `a2_finished_units.dart` helpers from Task 1.

- [ ] **Step 1: Write the failing test**

```dart
// test/content/a2_bilingual_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'a2_finished_units.dart';

final _arabic = RegExp(r'[؀-ۿ]');

void main() {
  test('every conversation line carries Arabic', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final line in lesson.encounterDialogue) {
          expect(line.ar.trim(), isNotEmpty,
              reason: '${lesson.id} line by ${line.speaker}');
        }
      }
    }
  });

  test('every activity prompt carries Arabic', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        expect(a.promptAr?.trim() ?? '', isNotEmpty, reason: a.id);
      }
    }
  });

  test('a bilingual field that is present but not a String fails the gate', () {
    // The parser deliberately degrades a non-String bilingual field to null
    // rather than throwing (see lib/content/models/non_blank.dart and the
    // spec's "Carried forward from step 1"), so the strictness lives here.
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        final raw = lesson.raw;
        for (final key in ['titleAr', 'textAr', 'sourceText']) {
          final value = raw[key];
          if (value != null) {
            expect(value, isA<String>(), reason: '${lesson.id}.$key');
          }
        }
        for (final a in lesson.activities) {
          for (final key in ['promptAr', 'textAr', 'sourceText', 'sourceCard']) {
            final value = a.raw[key];
            if (value != null) {
              expect(value, isA<String>(), reason: '${a.id}.$key');
            }
          }
        }
      }
    }
  });

  test('English fields contain no Arabic script', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        expect(_arabic.hasMatch(lesson.title), isFalse, reason: lesson.id);
        for (final a in lesson.activities) {
          // A matching activity legitimately pairs English with Arabic; its
          // prompt is still English.
          expect(_arabic.hasMatch(a.prompt), isFalse, reason: a.id);
        }
      }
    }
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/content/a2_bilingual_test.dart`
Expected: the conversation-line test FAILS — U1 has dialogue lines with empty `ar`. Paste the failure into your report.

- [ ] **Step 3: Commit**

```bash
git add test/content/a2_bilingual_test.dart
git commit -m "test: gate A2 units on bilingual completeness"
```

---

### Task 3: The answerable gate

**Files:**
- Create: `test/content/a2_answerable_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/content/a2_answerable_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';

import 'a2_finished_units.dart';

void main() {
  test('every mediation task supplies the material it asks about', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.mediation) continue;
        expect(a.sourceCard?.trim() ?? '', isNotEmpty,
            reason: '${a.id} asks the learner to relay nothing');
      }
    }
  });

  test('every listening activity has a transcript to speak', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.listening) continue;
        final transcript = a.raw['audioTranscript'];
        expect(transcript is String && transcript.trim().isNotEmpty, isTrue,
            reason: a.id);
      }
    }
  });

  test('every reading question supplies its text', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        for (final a in lesson.activities) {
          if (a.skill != Skill.reading) continue;
          final hasOwnText = (a.raw['sourceText'] as String?)?.trim().isNotEmpty ??
              false;
          final hasCard = a.sourceCard != null;
          final hasLessonText =
              (lesson.readingText?.text.trim().isNotEmpty) ?? false;
          expect(hasOwnText || hasCard || hasLessonText, isTrue,
              reason: '${a.id} has no text to read');
        }
      }
    }
  });

  test('every mastery speak or write task carries a STRUCTURED evaluation', () {
    // Presence is not enough. The A2 import carries A1's retired legacy
    // shape — an opaque list of rubric names, e.g.
    //   "evaluation": ["taskCompletion", "intelligibility", "accuracy"]
    // — which no grader reads. A1 was migrated off that to structured specs
    // (see DATA_MODEL.md's history); A2 must be authored with them.
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        final isProductive = a is SpeakActivity || a is WriteActivity;
        if (!isProductive || a.mode != ActivityMode.mastery) continue;
        final spec = a.raw['evaluation'];
        expect(spec, isA<Map>(),
            reason: '${a.id} still has the legacy rubric-name evaluation');
        final map = spec as Map;
        expect(map['type'], 'keywordChecklist', reason: a.id);
        final groups = map['requiredGroups'];
        expect(groups is List && groups.isNotEmpty, isTrue, reason: a.id);
        for (final group in groups as List) {
          expect(group is List && group.isNotEmpty, isTrue,
              reason: '${a.id} has an empty keyword group');
        }
        expect(map['minGroupsMatched'], isA<int>(), reason: a.id);
      }
    }
  });

  test('every interaction task gives the learner something to reply to', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.spokenInteraction) continue;
        final turns = a.raw['partnerTurns'] ?? a.raw['examinerTurns'];
        expect(turns is List && turns.isNotEmpty, isTrue,
            reason: '${a.id} is an interaction with no partner');
      }
    }
  });

  test('every word a lesson lists actually appears in that lesson', () {
    // The spec's rule: "Every listed word appears in its lesson's
    // conversation or text and is practised in at least one activity."
    // Only A2 records are checked — an A1 reference is revision, and the
    // lesson may legitimately only allude to it.
    final a2 = loadA2Bundle();
    final byId = {for (final l in a2.lexicon) l.id: l};
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        final haystack = [
          for (final line in lesson.encounterDialogue) line.en,
          lesson.readingText?.text ?? '',
          for (final a in lesson.activities) ...[
            a.prompt,
            '${a.raw['audioTranscript'] ?? ''}',
            '${a.raw['sourceText'] ?? ''}',
            '${a.raw['sourceCard'] ?? ''}',
            '${a.raw['options'] ?? ''}',
            '${a.raw['answer'] ?? ''}',
            '${a.raw['pairs'] ?? ''}',
          ],
        ].join(' ').toLowerCase();
        for (final id in lesson.lexicon) {
          final item = byId[id];
          if (item == null) continue; // an A1 reference
          expect(haystack, contains(item.headword.toLowerCase()),
              reason: '${lesson.id} lists ${item.headword} ($id) but never '
                  'uses it');
        }
      }
    }
  });

  test('no A1 sense is re-registered as an A2 record', () {
    final a1Words = {
      for (final l in loadA1Bundle().lexicon) l.headword.toLowerCase().trim(),
    };
    final offenders = <String>[];
    for (final l in loadA2Bundle().lexicon) {
      if (a1Words.contains(l.headword.toLowerCase().trim())) {
        offenders.add('${l.id} (${l.headword})');
      }
    }
    // A genuinely new sense of an A1 word is allowed; this gate lists them so
    // the reviewer can confirm each is a new sense, not a copy.
    expect(offenders, isEmpty,
        reason: 'these A2 records repeat an A1 headword — reference the A1 '
            'record instead, or confirm the sense is genuinely new');
  });
}
```

This file needs `import 'package:mohingo/content/models/domain_definitions.dart';`
for `Skill` and `ActivityMode`. `LexiconItem` exposes `id`, `headword` and
`partOfSpeech` (`lib/content/models/registry_items.dart:74`).

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/content/a2_answerable_test.dart`
Expected: the mediation and interaction tests FAIL (0 source cards, 0 partner turns in the bundle). Paste both failures.

- [ ] **Step 3: Commit**

```bash
git add test/content/a2_answerable_test.dart
git commit -m "test: gate A2 units on answerability"
```

---

### Task 4: The design-limits gate — balance, modes and conversation shape

**Files:**
- Create: `test/content/a2_design_limits_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/content/a2_design_limits_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';

import 'a2_finished_units.dart';

void main() {
  test('each unit is in skill balance', () {
    for (final unit in finishedA2Units()) {
      final acts = activitiesOf(unit).toList();
      int n(Skill s) => acts.where((a) => a.skill == s).length;
      final speaking = n(Skill.spokenInteraction) + n(Skill.spokenProduction);
      expect(n(Skill.listening), greaterThanOrEqualTo(10),
          reason: '${unit.id} listening');
      expect(n(Skill.reading), lessThanOrEqualTo(12), reason: '${unit.id} reading');
      expect(speaking, inInclusiveRange(6, 8), reason: '${unit.id} speaking');
      expect(n(Skill.writing), 3, reason: '${unit.id} writing');
      expect(n(Skill.mediation), 2, reason: '${unit.id} mediation');
    }
  });

  test('every guided lesson opens on a real conversation', () {
    for (final unit in finishedA2Units()) {
      for (final lesson in unit.lessons) {
        if (lesson.lessonType != 'encounter-focus-practice') continue;
        final lines = lesson.encounterDialogue;
        expect(lines.length, inInclusiveRange(4, 8), reason: '${lesson.id} lines');
        final speakers = {for (final l in lines) l.speaker.trim()};
        expect(speakers.length, inInclusiveRange(2, 3),
            reason: '${lesson.id} speakers');
      }
    }
  });

  test('each unit has one model text for its production lesson', () {
    for (final unit in finishedA2Units()) {
      final withText =
          unit.lessons.where((l) => l.readingText != null).toList();
      expect(withText.length, 1, reason: '${unit.id} readingText count');
      expect(withText.single.lessonType, 'integrated-production');
    }
  });

  test('no prompt is used more than three times in a unit', () {
    for (final unit in finishedA2Units()) {
      final counts = <String, int>{};
      for (final a in activitiesOf(unit)) {
        final key = a.prompt.trim().toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      }
      final overused = counts.entries.where((e) => e.value > 3).toList();
      expect(overused, isEmpty,
          reason: '${unit.id}: ${overused.map((e) => '"${e.key}" x${e.value}')}');
    }
  });

  test('at most one English-to-Arabic matching activity per unit', () {
    final arabic = RegExp(r'[؀-ۿ]');
    for (final unit in finishedA2Units()) {
      var translationMatches = 0;
      for (final a in activitiesOf(unit)) {
        if (a is! MatchActivity) continue;
        final pairs = a.raw['pairs'];
        if (pairs is! List || pairs.isEmpty) continue;
        final looksLikeTranslation = pairs.every(
          (p) => p is List && p.length == 2 && arabic.hasMatch('${p[1]}'),
        );
        if (looksLikeTranslation) translationMatches++;
      }
      expect(translationMatches, lessThanOrEqualTo(1), reason: unit.id);
    }
  });

  test("an activity's canDo objectives match the skill it evidences", () {
    const categoryBySkill = {
      Skill.listening: 'LISTENING',
      Skill.reading: 'READING',
      Skill.writing: 'WRITING',
      Skill.spokenProduction: 'PRODUCTION',
      Skill.spokenInteraction: 'INTERACTION',
      Skill.mediation: 'MEDIATION',
    };
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        final expected = categoryBySkill[a.skill]!;
        for (final objective in a.canDo) {
          // A mission's ACTION.* objective accepts evidence from any skill.
          if (objective.contains('.ACTION.')) continue;
          expect(objective, contains('.$expected.'),
              reason: '${a.id} (${a.skill}) claims $objective');
        }
      }
    }
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/content/a2_design_limits_test.dart`
Expected: skill balance, conversation shape and model-text tests all FAIL. Paste the three failures.

- [ ] **Step 3: Commit**

```bash
git add test/content/a2_design_limits_test.dart
git commit -m "test: gate A2 units on skill balance and lesson shape"
```

---

### Task 5: The length-band gate

**Files:**
- Modify: `test/content/a2_design_limits_test.dart` (add to the same file — these are design limits too, split into their own task only because the band table needs care)

- [ ] **Step 1: Add the band table and its tests**

```dart
/// The spec's length bands, by where the unit sits in the level.
({List<int> listening, List<int> reading, List<int> writing}) _bandsFor(
  String unitId,
) {
  final n = int.parse(unitId.split('-U').last);
  if (n <= 4) {
    return (listening: [30, 60], reading: [60, 100], writing: [55, 75]);
  }
  if (n <= 8) {
    return (listening: [50, 90], reading: [90, 140], writing: [65, 85]);
  }
  return (listening: [70, 120], reading: [120, 180], writing: [75, 100]);
}

int _words(String? s) =>
    RegExp(r"[A-Za-z']+").allMatches(s ?? '').length;
```

and the tests:

```dart
  test('listening input is inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).listening;
      for (final lesson in unit.lessons) {
        if (lesson.encounterDialogue.isNotEmpty) {
          final words = lesson.encounterDialogue
              .map((l) => _words(l.en))
              .fold<int>(0, (a, b) => a + b);
          expect(words, inInclusiveRange(band[0], band[1]),
              reason: '${lesson.id} conversation is $words words');
        }
        for (final a in lesson.activities) {
          if (a.skill != Skill.listening) continue;
          final words = _words(a.raw['audioTranscript'] as String?);
          expect(words, inInclusiveRange(band[0], band[1]),
              reason: '${a.id} transcript is $words words');
        }
      }
    }
  });

  test('the model text is inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).reading;
      for (final lesson in unit.lessons) {
        final text = lesson.readingText;
        if (text == null) continue;
        final words = _words(text.text);
        expect(words, inInclusiveRange(band[0], band[1]),
            reason: '${lesson.id} model text is $words words');
      }
    }
  });

  test('notices and source cards are 15-60 words', () {
    for (final unit in finishedA2Units()) {
      for (final a in activitiesOf(unit)) {
        for (final key in ['sourceText', 'sourceCard']) {
          final value = a.raw[key];
          if (value is! String || value.trim().isEmpty) continue;
          expect(_words(value), inInclusiveRange(15, 60),
              reason: '${a.id}.$key');
        }
      }
    }
  });

  test('every writing task carries a wordGuide inside its band', () {
    for (final unit in finishedA2Units()) {
      final band = _bandsFor(unit.id).writing;
      for (final a in activitiesOf(unit)) {
        if (a.skill != Skill.writing) continue;
        final guide = a.raw['wordGuide'];
        expect(guide, isA<List>(), reason: '${a.id} has no wordGuide');
        final g = (guide as List).cast<num>();
        expect(g.length, 2, reason: '${a.id} wordGuide shape');
        expect(g[0], band[0], reason: '${a.id} wordGuide low');
        expect(g[1], band[1], reason: '${a.id} wordGuide high');
      }
    }
  });
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/content/a2_design_limits_test.dart`
Expected: listening band FAILS (U1 transcripts are 13–23 words against a 30–60 band) and `wordGuide` FAILS (`[60,90]` against `[55,75]`). Paste both.

- [ ] **Step 3: Commit**

```bash
git add test/content/a2_design_limits_test.dart
git commit -m "test: gate A2 units on the spec's length bands"
```

---

### Task 6: The masterable gate and the release rule

**Files:**
- Create: `test/content/a2_masterable_test.dart`

- [ ] **Step 1: Write the test**

Read `test/content/` for A1's existing mastery test and follow its approach
for simulating correct answers — do not invent a second way of computing
mastery. Name the file you copied from in your report.

```dart
// test/content/a2_masterable_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/models/activity.dart';

import 'a2_finished_units.dart';

void main() {
  test('answering every mastery item correctly masters the unit', () {
    for (final unit in finishedA2Units()) {
      final evidenced = <String>{};
      for (final a in activitiesOf(unit)) {
        if (a.mode != ActivityMode.mastery) continue;
        evidenced.addAll(a.canDo);
      }
      for (final objective in unit.mastery.requiredObjectives) {
        expect(evidenced, contains(objective),
            reason: '${unit.id} requires $objective, which no mastery '
                'activity evidences');
      }
      for (final group in unit.mastery.requiredSkillGroups) {
        expect(group.any(evidenced.contains), isTrue,
            reason: '${unit.id} skill group $group has no evidence');
      }
    }
  });

  test('A2 stays a preview until every unit is finished', () {
    final a2 = kLevelCatalog.firstWhere((e) => e.levelId == 'a2');
    if (a2.availability == LevelAvailability.available) {
      expect(a2FinishedUnitIds.length, 12,
          reason: 'A2 is marked available with only '
              '${a2FinishedUnitIds.length} finished units');
    }
  });
}
```

- [ ] **Step 2: Run it**

Run: `flutter test test/content/a2_masterable_test.dart`
Expected: PASS today (mastery evidence is already reachable — see the audit). State in your report that it passed before any content change; it is a regression guard for the authoring tasks, which will move activities between modes.

- [ ] **Step 3: Commit**

```bash
git add test/content/a2_masterable_test.dart
git commit -m "test: gate A2 on masterable units and the release rule"
```

---

### Task 7: Author A2-U1 lessons L1 and L2

From here the work is content. Read `assets/content/en/A1/a1-course-bundle.json`'s
`A1-U3` first and match its register and rhythm — A2 is the same course
continuing, not a different author's.

**Files:**
- Modify: `assets/content/en/A2/a2-course-bundle.json` (unit `A2-U1`, lessons `A2-U1-L1` and `A2-U1-L2`)

**The content rules for every guided lesson (L1–L5):**

1. `encounter.dialogue`: 4–8 lines, 2–3 named speakers, **every line has `ar`**, the whole conversation 30–60 English words, and it models the lesson's grammar and words naturally.
2. `A01` (encounter, listening): a **gist** question about the conversation — what the situation is, what someone wants — never a detail that just re-reads a line.
3. `A02`, `A03` (practice, reading): one on form, one on meaning.
4. `A04` (mastery): a receptive item on **new** input — its own `audioTranscript` (listening) or `sourceText` (reading), never the conversation again.
5. `A05` (mastery): the productive task from the activity map, with its `evaluation` (a `keywordChecklist`) and, for interaction, `partnerTurns`.

- [ ] **Step 1: Write L1's conversation**

L1 teaches present simple vs continuous (routine vs right now). Use this
exact conversation — it is 57 words, inside the 30–60 band, uses the target
contrast four times, and its Arabic is written as Arabic, not traced from
the English:

```json
"encounter": {
  "dialogue": [
    {"speaker": "Layla", "en": "Omar! It's good to see you. How are things?", "ar": "عمر! سعيدة برؤيتك. كيف الأحوال؟"},
    {"speaker": "Omar", "en": "Busy, actually. I'm working at the new clinic this month.", "ar": "مشغول فعلاً. أعمل هذا الشهر في العيادة الجديدة."},
    {"speaker": "Layla", "en": "The one near the station? I thought you worked at the hospital.", "ar": "التي بجانب المحطة؟ كنت أظنّك تعمل في المستشفى."},
    {"speaker": "Omar", "en": "I do, normally. But they need extra people right now.", "ar": "أعمل فيه عادةً، لكنهم يحتاجون موظفين إضافيين هذه الأيام."},
    {"speaker": "Layla", "en": "How often do you go?", "ar": "كم مرة تذهب؟"},
    {"speaker": "Omar", "en": "Three days a week. It's tiring, but I'm learning a lot.", "ar": "ثلاثة أيام في الأسبوع. متعب، لكنني أتعلّم الكثير."}
  ]
}
```

- [ ] **Step 2: Rewrite L1's five activities to the activity map**

`A01` encounter/listening gist; `A02` practice/reading (gap on the
contrast); `A03` practice/reading (meaning); `A04` mastery/listening with
its **own** 30–60 word `audioTranscript`; `A05` mastery/spokenProduction
with a `keywordChecklist` evaluation. Keep the existing five ids.

Two worked examples, so the shape is not in doubt. `A01` today asks a
detail question against a 19-word transcript and claims a `PRODUCTION`
objective it cannot evidence. Authored, it becomes a gist question on the
conversation, tagged only with what listening evidences:

```json
{
  "id": "A2-U1-L1-A01",
  "lessonId": "A2-U1-L1",
  "type": "textChoice",
  "mode": "encounter",
  "skill": "listening",
  "canDo": ["A2.U1.LISTENING.UNDERSTAND_LIFE_UPDATE"],
  "prompt": "Why is Omar working at the clinic this month?",
  "promptAr": "لماذا يعمل عمر في العيادة هذا الشهر؟",
  "options": ["He changed jobs", "They need extra people", "He is studying there"],
  "answer": "They need extra people"
}
```

and `A05` carries a real grader instead of rubric names:

```json
{
  "id": "A2-U1-L1-A05",
  "lessonId": "A2-U1-L1",
  "type": "speak",
  "mode": "mastery",
  "skill": "spokenProduction",
  "canDo": ["A2.U1.PRODUCTION.DESCRIBE_CURRENT_LIFE"],
  "prompt": "Say what you usually do in a week, and one thing that is different at the moment.",
  "promptAr": "تحدّث عمّا تفعله عادةً خلال الأسبوع، وعن شيء واحد مختلف هذه الأيام.",
  "accepted": [],
  "evaluation": {
    "type": "keywordChecklist",
    "requiredGroups": [
      ["usually", "normally", "every", "most days", "on weekdays"],
      ["at the moment", "right now", "this month", "this week", "these days"]
    ],
    "minGroupsMatched": 2,
    "onlineRefinement": "grammarCheck"
  },
  "fallbackSkill": "writing",
  "fallbackCountsFor": "accessOnly"
}
```

Note what the keyword groups are doing: they mark the *contrast* the lesson
teaches — habitual language in one group, "right now" language in the
other — so a learner who only describes their routine does not pass a task
about routine versus change.

- [ ] **Step 3: Do the same for L2**

L2 continues the unit's Can-Dos with follow-up questions (*How long / How
often*). Same shape, same rules, a different situation — do not reuse L1's
speakers or setting.

- [ ] **Step 4: Run the gates over U1**

Run: `flutter test test/content/`
Expected: still failing (L3–L7 are untouched), but the failures must now
name L3+ rather than L1 or L2. Paste the failing reasons.

- [ ] **Step 5: Commit**

```bash
git add assets/content/en/A2/a2-course-bundle.json
git commit -m "content: author A2-U1 lessons 1 and 2"
```

---

### Task 8: Author A2-U1 lessons L3, L4 and L5

**Files:**
- Modify: `assets/content/en/A2/a2-course-bundle.json` (`A2-U1-L3`, `A2-U1-L4`, `A2-U1-L5`)

- [ ] **Step 1: Author all three lessons**

Same rules as Task 7, following the activity map: L3's `A04` is listening
and `A05` is spokenProduction; **L4's `A04` is reading** (give it a 15–60
word `sourceText`) and its `A05` is writing with `wordGuide: [55, 75]`;
L5's `A04` is listening and `A05` is spokenInteraction with `partnerTurns`.

Each lesson needs its own conversation (4–8 lines, 2–3 speakers, 30–60
words, Arabic on every line) and its own new input for `A04`.

- [ ] **Step 2: Run the gates**

Run: `flutter test test/content/`
Expected: conversation, bilingual and listening-band failures for L1–L5 are
gone; L6/L7 failures remain.

- [ ] **Step 3: Commit**

```bash
git add assets/content/en/A2/a2-course-bundle.json
git commit -m "content: author A2-U1 lessons 3 to 5"
```

---

### Task 9: Author A2-U1 lesson L6, the model text

**Files:**
- Modify: `assets/content/en/A2/a2-course-bundle.json` (`A2-U1-L6`)

- [ ] **Step 1: Add the lesson-level `readingText`**

The lesson gains a sibling of `activities`:

```json
"readingText": {
  "title": "A month in a new city",
  "text": "<60-100 English words>",
  "textAr": "<the same text in natural Arabic>"
}
```

It is a model of what the learner will write at `A04` — a short personal
update using the unit's grammar: what someone usually does, what is
different right now, and why.

- [ ] **Step 2: Rewrite L6's five activities**

`A01` encounter/reading gist on the model text; `A02` practice/reading
detail on it; `A03` mastery/listening on a **new** recording (its own
30–60 word `audioTranscript`); `A04` mastery/writing with
`wordGuide: [55, 75]` and a `keywordChecklist` evaluation carrying
`onlineRefinement: "grammarCheck"`; `A05` mastery/mediation with a 15–60
word `sourceCard` and its own evaluation.

- [ ] **Step 3: Run the gates**

Run: `flutter test test/content/`
Expected: the model-text test now passes; only L7 failures remain.

- [ ] **Step 4: Commit**

```bash
git add assets/content/en/A2/a2-course-bundle.json
git commit -m "content: author A2-U1 lesson 6 with its model text"
```

---

### Task 10: Author A2-U1 lesson L7, the mission

**Files:**
- Modify: `assets/content/en/A2/a2-course-bundle.json` (`A2-U1-L7`)

- [ ] **Step 1: Author the six mission activities**

Keep the unit's existing mission scenario. Every input is **new** — never
reused from L1–L6. Per the activity map: `A01` practice/listening (its own
transcript), `A02` mastery/spokenInteraction (`partnerTurns`), `A03`
mastery/spokenProduction, `A04` mastery/writing (`wordGuide: [55, 75]`),
`A05` mastery/mediation (`sourceCard`), `A06` mastery/reading
(`sourceText`). Every mastery speak/write/mediation activity carries a
`keywordChecklist` evaluation; speak fallbacks keep
`"fallbackSkill": "writing"` and `"fallbackCountsFor": "accessOnly"`.

The mission's `ACTION.*` objectives accept evidence from any skill, so keep
each activity's `canDo` to the objectives its own skill evidences plus the
unit's `ACTION.*` objective where it genuinely completes the task.

- [ ] **Step 2: Run the gates**

Run: `flutter test test/content/`
Expected: every test except skill balance and vocabulary now passes.

- [ ] **Step 3: Commit**

```bash
git add assets/content/en/A2/a2-course-bundle.json
git commit -m "content: author A2-U1's mission"
```

---

### Task 11: Bring U1's vocabulary up to strength and close the gates

**Files:**
- Modify: `assets/content/en/A2/a2-course-bundle.json` (`lexicon`, `chunks`, and U1's lesson `lexicon` lists)

- [ ] **Step 1: Take U1 from 18 to about 35 senses**

Add A2 lexicon records for the words the authored lessons actually use.
Task 3's "every word a lesson lists actually appears in that lesson" gate
enforces the direction that matters — you cannot list a word the lesson
never uses. Nothing forces the reverse, so the judgement left to you is
which of the words your lessons *do* use are worth registering as senses.
Aim for about 35 across the unit and expect the reviewer to sample them.

Where a word is already an A1 record, **reference the A1 id** from the
lesson's `lexicon` list instead of creating an A2 record. Only a genuinely
new sense (A1 *order* = a request; A2 *order* = a sequence) earns its own
A2 record. Examples are bilingual `{"en": "...", "ar": "..."}`.

- [ ] **Step 2: Run every gate**

Run: `flutter test test/content/`
Expected: all green.

- [ ] **Step 3: Run the whole suite**

Run: `dart format .; flutter analyze; flutter test`
Expected: `No issues found!` and every test passing. Report the count.

- [ ] **Step 4: Commit**

```bash
git add assets/content/en/A2/a2-course-bundle.json
git commit -m "content: bring A2-U1's vocabulary up to strength"
```

---

### Task 12: Documentation

**Files:**
- Modify: `docs/TESTING.md`, `docs/ROADMAP.md`, `docs/PRODUCT.md`

Derive the list yourself from CLAUDE.md's Definition-of-done table **and**
the spec's "Documentation" section, exactly as the spec's carried-forward
rule requires — the list above is what I expect, not a closed set. For each
row of that table you decide does not apply, give one line of reasoning in
your report.

- [ ] **Step 1: Write the updates**

- **TESTING.md** — the `test/content/a2_*` suite: what each file gates, and
  the finished-units list as the mechanism (a unit joins it only when
  authored; A2 cannot go available until all twelve are on it).
- **ROADMAP.md** — A2 step 4 (pilot) landed; U1 is authored content, U2–U12
  are still the imported skeleton.
- **PRODUCT.md** — only if its A2 wording now misstates what exists.

Bump each edited doc's **Last verified** line to the day of the edit,
naming the change and this branch, in that file's own style.

- [ ] **Step 2: Commit**

```bash
git add docs/
git commit -m "docs: record the A2 content gates and the pilot unit"
```

---

## Self-review notes (for the executor)

- Tasks 1–6 must be committed **failing**. That is deliberate: the gates
  define the standard, and Tasks 7–11 are judged by turning them green.
  Task 6 is the exception — it passes from the start and guards against the
  authoring tasks moving an activity out of `mastery` mode.
- The gates only run over `a2FinishedUnitIds`. Adding a unit to that list
  before authoring it will fail the build loudly, which is the intent.
- Nothing in this plan marks A2 available. That is the release step, and
  Task 6's release rule blocks it until all twelve units are finished.
