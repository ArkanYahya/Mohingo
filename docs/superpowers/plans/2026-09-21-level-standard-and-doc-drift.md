# The Level Standard, and the Last of the Doc Drift — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write down what a CEFR level must be and what it costs to add one, so B1 is a catalogue entry, a bundle, a config row and a finished-units list — and fix the last documentation paths that point at files which no longer exist.

**Architecture:** One new document, `docs/LEVEL_STANDARD.md`, states the content rules a level must meet and the four registration steps that hold it to them, each rule naming the gate that enforces it. An ADR records the decision that every level meets one standard, with the two reasoned exceptions A1 carries. `CLAUDE.md` gains a Start-here row and a Definition-of-done row so the standard is found and kept current. Separately and independently, six stale references to a directory that moved are corrected.

**Tech Stack:** Markdown. No code.

**Spec:** No design doc — this plan is the design.

## Global Constraints

- **Verify against the code, not the docs.** Every rule this document states must name the test that enforces it, and that test must exist. A rule with no enforcement is written as a rule with no enforcement, plainly labelled.
- **Do not foreclose open product decisions.** Whether content moves to SQLite, and whether updates arrive over the air, are the product owner's to make. `LEVEL_STANDARD.md` describes what a level's *content* must be, not how it is delivered, and says so.
- Do not re-author content, and do not regenerate any bundle from `reference/`.
- When a doc is edited, bump its **Last verified** line to the day of the edit with the branch, per CLAUDE.md.

## Sequencing

**Task 1 is independent — do it first, whatever else has landed.** Tasks 2 to 4 describe the machinery built by the other three plans in this wave, so they run after:

- `2026-09-21-content-versioning-and-stale-units.md`
- `2026-09-21-published-id-stability-guard.md`
- `2026-09-21-level-parameterised-content-gates.md`

If those have not landed, Task 1 still stands on its own and the rest waits. Do not describe machinery that does not exist yet — that is the exact failure this wave is correcting.

---

### Task 1: Correct the paths that point at nothing

**Files:**
- Modify: `docs/adr/0004-local-only-v1-no-firebase-backend.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/GLOSSARY.md`, `docs/SECURITY.md`, `CLAUDE.md`

**The facts, verified at `c834e42`:**

The curriculum-authoring package lives at `reference/a1-modular-course/` (alongside `reference/a2-modular-course/`). It was at `docs/a1-modular-course/` until 2026-09-19, and **six references across five files still name the old path**:

| File | Line | What it says |
|---|---|---|
| `docs/adr/0004-local-only-v1-no-firebase-backend.md` | 15 | `docs/a1-modular-course/dist/a1-course-bundle.json` |
| `docs/ARCHITECTURE.md` | 4 | the same, in the 2026-09-08 Last-verified entry |
| `docs/DATA_MODEL.md` | 6 | the same, in the 2026-09-08 Last-verified entry |
| `docs/DATA_MODEL.md` | 147 | `docs/a1-modular-course/README_AR.md` |
| `docs/GLOSSARY.md` | 4 | the bundle path, in the 2026-09-02 Last-verified entry |
| `docs/GLOSSARY.md` | 38 | `docs/a1-modular-course/` in the ContentItem row |
| `docs/SECURITY.md` | 11 | `docs/a1-modular-course/` as the dev-time authoring tool |

Correcting the historical Last-verified entries is right, not revisionism: the point of those lines is what was verified, and the date carries the history. `ARCHITECTURE.md`'s own 2026-09-19 entry already records that the pipeline moved, so the file currently contradicts itself.

- [ ] **Step 1: Correct all six**

Replace `docs/a1-modular-course` with `reference/a1-modular-course` in each. Check afterwards that nothing remains:

```bash
grep -rn "docs/a1-modular-course\|docs/a2-modular-course" --include=*.md . | grep -v '^./build/'
```
Expected: no output.

- [ ] **Step 2: Add a note in ADR 0004**

An ADR records a decision at a moment. Correct the path inline, and add one sentence at the end of its context saying the authoring package moved to `reference/` on 2026-09-19 and the path here was corrected to match — so a reader knows the decision was not silently re-litigated.

- [ ] **Step 3: Sweep for other dead paths**

Every backticked path in the docs should resolve. Check them:

```bash
grep -rhoE '`[a-zA-Z0-9_./-]+\.(md|dart|json|yaml|arb)`' docs/ CLAUDE.md README.md \
  | tr -d '`' | sort -u | while read -r p; do
      [ -e "$p" ] || [ -e "docs/$p" ] || echo "MISSING: $p"
    done
```

Triage what it prints. A path that names a file the repo genuinely does not have is either a correction or a claim to delete; a path that is a fragment, a glob or an illustrative name is neither, and is left alone. Report each decision in one line — do not fix anything you cannot verify.

- [ ] **Step 4: Fix CLAUDE.md's Start-here row for API_CONTRACT.md**

It currently reads "Firestore collection structure and access rules (no custom REST API)". The document itself says, correctly, **"Not applicable for v1"** — the app has no backend of any kind, per ADR 0004. A reader of CLAUDE.md alone would conclude Firestore is in use. Replace the cell with what the doc actually is: a placeholder for the post-v1 sync contract, not applicable in v1.

- [ ] **Step 5: Bump and commit**

Bump each edited doc's **Last verified** line to the day of the edit, naming the change and the branch, in that file's own style.

```bash
git add docs/ CLAUDE.md
git commit -m "docs: point the authoring-package paths at where it actually is"
```

**Not in this task:** `DATA_MODEL.md`'s `content_versions` entry, which states an intention as a behaviour. That is corrected by `2026-09-21-content-versioning-and-stale-units.md` Task 7, in the same commit as the behaviour that makes it true. Correcting it here would either duplicate that or make the doc claim something still unbuilt.

---

### Task 2: Write `docs/LEVEL_STANDARD.md`

**Files:**
- Create: `docs/LEVEL_STANDARD.md`

**Interfaces:**
- Consumes: `test/content/levels/level_gate_config.dart` and the ported gate suite; `tool/update_published_ids.dart` and `test/content/published/`; `lib/content/catalog/level_catalog.dart`.

**Audience.** This is written for whoever adds B1 — someone who has the curriculum content and needs to know what shape it must take and what to wire up. Not for the product owner, and not a rationale document; the rationale goes in the ADR.

**The rule for every claim in it:** name the gate that enforces it. Where nothing enforces a rule, say so in the same sentence. A standard that mixes enforced rules with aspirations, without marking which is which, is worse than one that only lists the enforced ones.

- [ ] **Step 1: Write the four registration steps**

What adding a level costs, verified against the code as you write each one:

1. **A catalogue entry** in `kLevelCatalog` (`lib/content/catalog/level_catalog.dart`): `levelId`, `cefrCode`, `availability`, `bundleAssetPath`, `prerequisiteLevelId`. A level ships as `comingSoon` with no bundle, becomes `preview` when its bundle exists but its lessons stay closed, and becomes `available` only when its release rule passes. State the `--dart-define=MOHINGO_PREVIEW_LEVELS=<id>` development flag and that it opens only the levels it names.
2. **A bundle** at `assets/content/en/<CEFR>/<level>-course-bundle.json`, registered in `pubspec.yaml`.
3. **A gate config row** in `test/content/levels/level_gate_config.dart`, holding the level's numbers and its finished-units list. Every gate in `test/content/levels/` then runs over it automatically.
4. **A published-ids snapshot**: `dart run tool/update_published_ids.dart`, committed. From that moment the level's ids are permanent, its activity modes frozen and its `canDo` tags append-only.

Say plainly what is *not* in the list: no new screen, no new provider, no new repository, no migration. Verify that claim before writing it — `grep -rn "'a1'\|'a2'" lib/ --include=*.dart` should show nothing that would need a third branch. If it does, the standard says what a third level would additionally cost, honestly.

- [ ] **Step 2: Write the content rules**

Each with its gate. Transcribe the numbers from `level_gate_config.dart` rather than from memory or from the A2 spec:

- **Unit shape** — 7 lessons, 36 activities, 6 encounter / 12 practice / 18 mastery (`level_structure_test.dart`).
- **Skill balance** — the per-level ranges across listening, reading, speaking, writing and mediation (`level_design_limits_test.dart`).
- **Bilingual throughout** — every learner-facing string carries Arabic, written natively rather than translated, and English fields carry no Arabic script (`level_bilingual_test.dart`, and [UX_PRINCIPLES.md](UX_PRINCIPLES.md)).
- **Answerable** — every listening activity has a transcript, every reading question its text, every mediation task its source, every interaction task its partner turns, every closed question a right answer among its options and a wrong one to pick (`level_answerable_test.dart`).
- **Gradeable** — every mastery `speak` or `write` task carries a structured `keywordChecklist`, and **no `speak` rubric in any bundle carries `onlineRefinement`** — the boundary from [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md) (`online_refinement_boundary_test.dart`).
- **Masterable, and failable** — a unit's required objectives must be ones its activities can evidence, each with enough carriers, and a unit must declare mastery it could actually fail (`level_masterable_test.dart`).
- **Length bands** — texts climb across a level; each level's tiers live in its config (`level_design_limits_test.dart`).
- **Vocabulary floor** — the minimum new senses a unit teaches (`level_design_limits_test.dart`).
- **Capstones** — a Final Mission and a Final Assessment, every required skill a section the exit contains, both marked to the same pass mark (`level_capstones_test.dart`).
- **Distinct ids across levels**, and distinct prompts within a level (`level_config_test.dart`, `level_design_limits_test.dart`).

- [ ] **Step 3: Write the self-containment rule**

The product owner's decision, recorded here as the rule it is:

> A level is **self-contained for vocabulary**: a word or phrase a lesson teaches is registered in that level's own lexicon, never borrowed from an earlier level's registry. A level **may reference an earlier level's grammar record** where a lesson revises a structure taught earlier, rather than duplicating it — grammar is a small, stable set that learners genuinely return to, while a re-registered word silently splits its review history across two ids.

Name the enforcement: `level_structure_test.dart`'s reference-resolution gate resolves ids against the level and its prerequisite, and `level_answerable_test.dart` holds the "no earlier-level sense is re-registered" rule. Confirm both still do what that sentence says before writing it.

- [ ] **Step 4: Write the exceptions section**

A1's two declared exceptions — U0 and U1's shape, and A1's lesson-wide Can-Do tagging — with their reasons, and the rule that governs adding another: an exception is a *value with a reason* in the gate config, never a skip, and a new level does not get one. A new level is authored to the standard; there is nothing to grandfather.

- [ ] **Step 5: Write what this document does not decide**

One short section, so nobody reads a delivery decision into a content standard:

- **How content is delivered** — bundled asset today, per [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Whether it moves to SQLite is open, and nothing in this standard depends on the answer.
- **Whether content updates over the air** — open. The content-versioning layer records what loaded and notices what changed; it does not fetch.
- **What a level costs to author.** This is the shape, not the schedule.

Also state the one known limitation a level author will hit: **passing a Final Assessment does not mark a level complete** (README's "Known limitations", [ROADMAP.md](ROADMAP.md)).

- [ ] **Step 6: Verify every gate name resolves**

```bash
ls test/content/levels/ && grep -rn "onlineRefinement" test/content/online_refinement_boundary_test.dart | head -3
```

Every test file `LEVEL_STANDARD.md` names must exist. A standard that cites gates by names nobody checked is the same failure it exists to prevent.

- [ ] **Step 7: Commit**

```bash
git add docs/LEVEL_STANDARD.md
git commit -m "docs: what a CEFR level must be, and what adding one costs"
```

---

### Task 3: The ADR

**Files:**
- Create: `docs/adr/0007-one-standard-for-every-level.md`
- Modify: `docs/adr/README.md` (if it holds an index — check)

`0006-multiple-levels.md` is the highest existing number, so this is **0007**. Follow `docs/adr/0000-template.md` exactly.

- [ ] **Step 1: Write it**

- **Context:** A2 was gated by 47 tests across 7 hand-written A2-specific files; A1 — the level every learner meets first — had five. Every rule was written as A2-specific code, so B1 would have been an eighth copy, differing from the seventh in ways nobody would notice. Separately, ids were declared permanent in prose with nothing checking it, while `activity_attempts` stores them as plain strings with no foreign key.
- **Decision:** One gate suite, parameterised by a per-level config. A level's differences are declared exceptions — a value plus a written reason — never skips. Ids are permanent once published, `mode` frozen, `canDo` append-only, all enforced by a committed snapshot. Levels are self-contained for vocabulary and may reference an earlier level's grammar. `docs/LEVEL_STANDARD.md` is the standard; adding a level is a catalogue entry, a bundle, a config row and a finished-units list.
- **Consequences:** Adding B1 costs configuration rather than code. A1 is now held to the standard, which surfaced real defects (list them, from the level-gates plan's Task 7 report). Retiring content is deliberately harder: a published activity cannot be deleted, only repaired or superseded. Two A1 exceptions are permanent, because removing them would move published ids.
- **Alternatives considered:** keep per-level suites (rejected: the eighth copy problem, and A1 stays unprotected); rewrite A1 to the standard (rejected: moves published ids, invalidating every existing learner's recorded evidence); enforce id stability by convention (rejected: that is what we had).

- [ ] **Step 2: Commit**

```bash
git add docs/adr/
git commit -m "docs: ADR 0007 — one standard every level is held to"
```

---

### Task 4: Wire the standard into CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Start-here table**

Add a row: `| [docs/LEVEL_STANDARD.md](docs/LEVEL_STANDARD.md) | What a CEFR level must contain, and what adding one costs |`. Place it after ROADMAP.md — a reader goes scope, sequencing, then level standard.

- [ ] **Step 2: Definition-of-done table**

Add a row: `| A new CEFR level, or a change to what a level must contain | [docs/LEVEL_STANDARD.md](docs/LEVEL_STANDARD.md) + the level's config row in test/content/levels/ |`.

- [ ] **Step 3: Correct the header paragraph**

CLAUDE.md's opening block describes the A2 gates as `test/content/a2_*` — 7 files, 47 tests, over an `a2FinishedUnitIds` list. After the level-gates plan lands, that is false in every particular. Replace with one sentence describing the suite as it is, and say that the release rule is what permits `available`. Keep the block's length roughly as it is — it is already long.

- [ ] **Step 4: Verify the whole entry point**

Read CLAUDE.md top to bottom against the repo and fix anything else that no longer holds. Specifically check: the Commands block, the two bundle paths, the claim that there is no `integration_test/` suite, and every Start-here link resolving.

- [ ] **Step 5: Full suite, then commit**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

```bash
git add CLAUDE.md
git commit -m "docs: point the entry point at the level standard"
```

---

## Self-review notes

- **Task 1 is deliberately first and deliberately independent.** It is six string corrections that are true today, and they should not wait behind three engineering plans.
- **Every rule in `LEVEL_STANDARD.md` names its gate, or admits it has none.** This is the whole reason the document is worth writing rather than restating the A2 spec — a standard nothing enforces is how the repo arrived at "ids are stable" being a sentence with no test behind it.
- **The "does not decide" section exists to protect two open product decisions.** A level standard is exactly the kind of document that quietly hardens a delivery assumption into a requirement, and both SQLite delivery and over-the-air updates are the product owner's calls.
- **Task 2 Step 1 asks the author to verify the "no new code" claim rather than assert it.** That claim is the document's headline, and it was false for A2 until step 2b — the level was released while ten screens still loaded A1 by name.
