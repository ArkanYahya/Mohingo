# A2 Level — continuing the A1 course into CEFR A2

**Status:** Implemented — all six steps have landed and **A2 was released on 2026-09-21** (`feature/a2-pilot-u1`). Step 2b (Home, Tests, Review, Vocabulary, Grammar and placement) was built in five parts: Tests and both capstones, then Home — including Home's "Start A2" offer — then Vocabulary and Grammar, with the A1/A2 filter (Vocabulary stays a flat searchable list; only Grammar groups by unit, as it already did), then the Review tab, which as designed spans every level rather than following one, and finally the block placement test of Design 4, which covers every released level and whose measured lengths match the design's estimates exactly (7 / 16 / 25 / 25 — see the foot of this document). Read "What actually shipped" at the foot of this document before trusting any table above it: several were written before anyone counted what the import contained.
**Date:** 2026-09-19 (design), 2026-09-21 (outcome recorded)

## Context

The app ships one CEFR level, A1 (`assets/content/en/A1/a1-course-bundle.json`). An A2 curriculum package exists at `reference/a2-modular-course/` (bundle: `dist/a2-course-bundle.json`, contentVersion `A2-COMPLETE-A1-CONTRACT-2026.09.19`). It was generated to fit A1's data contract, but it can't be shipped as-is: it won't load, parts of it can't be answered or marked, and it's noticeably weaker than A1 as teaching material. This document records what A1 actually is, what the A2 reference is, and the agreed design for turning the reference into A2 — content and app.

### What A1 is (verified against the shipped bundle and code)

- 13 units: `A1-U0` (starter, "English Essentials") + `A1-U1`…`A1-U12`; 89 lessons, 446 activities; registries of 85 grammar records, 354 lexical senses, 143 chunks.
- Core unit = 7 lessons: L1–L5 guided (`encounter-focus-practice`: a short named-speaker dialogue → key phrases → activities), L6 built around a short text (`readingText`), L7 a mission (6 activities). 36 activities per unit, split 6 `encounter` / 12 `practice` / 18 `mastery`.
- Six skills; mastery per Can-Do objective (≥2 `mastery` answers scoring ≥0.75) plus unit-level skill-group coverage (`MasteryAggregationService`). Recommendation only, never a lock.
- Speaking graded for task completion via on-device STT; typed fallback never counts as speaking. Open answers graded by structured `EvaluationSpec`s (mostly `keywordChecklist`), optional LanguageTool pass.
- Final Mission (6 stages, 12 activities) and Final Assessment (16 L / 16 R / 2 W / 4 S / 2 M), scored per skill, pass mark 0.6 per skill.
- Placement: `PlacementTestScreen` scans A1 units in order, up to 3 practice-mode receptive items per unit, stops at the first failing unit (≥2 items, <60%).
- Progression: situational/functional, chunk first then pattern. Grammar runs be → have → there is/are → present simple (all forms) → can, like + -ing → countable/uncountable, some/any → object pronouns, one/ones → imperatives, place prepositions → *should* (chunk) → present continuous → *going to*, present continuous for arrangements (chunk). Listening clips grow from ~3 to ~11 words on average; writing tasks from 25–45 to 55–75 words.
- An A1 graduate has **not** met: any past tense (only the fixed phrase "I ordered…"), comparatives, the present perfect, modals beyond *can*/*should*, conditionals.

### A1 limitations found (relevant to A2)

1. **Texts the app never shows.** `TextChoiceActivity.sourceText` is parsed but not rendered — 27 A1 reading questions ask about a text the learner can't see (e.g. `A1-U4-L7-A02`). Lesson-level `readingText` (A1 L6s) and mediation `sourceCard` (`A1-FINAL-ASSESS-M01`/`M02`) are never rendered either, nor are `examinerTurns` (`A1-FINAL-ASSESS-S02`). A1's 11 `readingText.textAr` values are truncated stubs (e.g. `"خطة ليوم السبت..."`).
2. **A1 hard-coded.** `courseContentProvider('a1')` appears in 23 files (router gate, Home, Learn, Review, Vocabulary, Grammar, Tests, lesson player, enrolment, refinement drain). Several ARB strings say "A1". ROADMAP.md's "no new app mechanics required" is not true today.
3. **Loose evidence tagging.** Every activity carries its lesson's full `canDo` list, so a listening item counts as evidence for a production objective. (Shared with the A2 reference. A1 keeps this for now — see Non-goals.)

### What the A2 reference is

Keep: same contract and lesson/mission/assessment shape; 12 core units whose themes spiral A1's up a level plus new domains (Life Now, Past Experiences, People & Relationships, Home & Neighbourhood, Food/Cooking/Services, Travel Plans, Health & Well-being, Work & Study, Technology & Communication, Stories & Entertainment, Nature & Everyday Problems, Invitations & Events); a mostly sound A2 grammar line; harder missions; "Host a Visitor" Final Mission; 44-item Final Assessment (18/18/2/4/2).

Blockers:
- **Doesn't parse:** lexicon `examples` are `{en, ar}` objects; `LexiconItem.fromJson` expects strings.
- **Can't be mastered:** all 136 productive activities use legacy rubric-name arrays (`["taskCompletion", …]`), which `EvaluationSpec.fromJson` maps to `null` → `notAutoGraded`, so no productive evidence is ever recorded.
- **Unanswerable:** all 108 `textChoice` items depend on the unrendered `sourceText`; none of the 24 unit mediation tasks carries source material, and at least 10 productive prompts refer to material that doesn't exist ("Read two short profiles provided by the app…").
- **Missing Arabic:** 38 of 72 encounter lines have `ar: ""`.

Weaker than A1:
- One template (`tools/authoring/helpers.mjs`) builds every lesson as the same 5 steps; step 2 is always "Match the key language to its Arabic meaning." (72×). 291 distinct prompts in 432 activities (A1: 427/446).
- Every encounter is a single "Narrator" paragraph (72/72), identical to the A01 source.
- Listening 5–7 items/unit (A1: 12–13); reading 19–21.
- Input shorter than output: listening avg ~20 words (max 28), reading max 36, no reading passages — but writing tasks rise to 90–125 words and 80–120 in the Final Assessment (B1-level output).
- Vocabulary thin and duplicated: 216 senses (18/unit; A1 had 354); 30 re-register A1 senses under new IDs, breaking A1's "reuse the ID, never copy the record" rule; only 56% of a lesson's listed words appear in its activities (A1: 85%).
- Grammar: present perfect missing; comparatives ×2, *have to* ×2, first conditional ×2, purpose *to* ×3, polite requests ×4, linkers ×6 registered under different IDs; *should*, *Would you like to…?*, imperatives, object pronouns re-registered as new.

## Decisions

| # | Decision | Chosen |
|---|---|---|
| 1 | How far to change the reference | **Blueprint:** keep units, themes, Can-Dos, grammar order, surviving IDs, mission/assessment design; rewrite lessons to A1's standard |
| 2 | How levels coexist | **One journey with a current level;** Review shared across levels; Vocabulary/Grammar open on the current level with a level filter |
| 3 | Placement | **One test across A1 + A2,** block pass with drill-down |
| 4 | Build/release | **Pilot unit (A2-U1) first, then batches of ~3 units;** A2 not openable by learners until complete |
| 5 | Where A2 content lives | **The shipped bundle is the source of truth** (`assets/content/en/A2/a2-course-bundle.json`), guarded by Dart content tests — same rule as A1 |
| 6 | Lock | **Locked preview while A2 is being built; soft lock after release** (opens on A1 complete, a placement result in A2, or "Open A2 anyway") |

## Design 1 — language progression

### Grammar

> **Superseded 2026-09-20 by the product owner (step 4, pilot review).** An
> A2 lesson does **not** list A1 ids at all. A learner in A2 is assumed to
> know A1 — whether they finished it here or arrived already knowing it —
> so A2 teaches A2, and the A2 bundle stays self-contained. A1 material is
> still *used* freely in A2 texts and conversations; it is simply not
> listed as something the lesson teaches or enrols into review. Where A2
> genuinely needs a different sense of a word A1 taught (A1 *change* = the
> verb, A2 *change* = the noun), that stays an A2 record, as below.
> Consequence recorded in [ADR 0006](../../adr/0006-multiple-levels.md):
> the cross-level machinery built in step 1 — `CourseContentIndex`'s
> `prerequisite`, the provider loading A1 alongside A2, and the "From A1"
> badge — has no consumer for vocabulary. It is kept, unused, for grammar
> and for later levels.

~~A1 structures are **reviewed by reference, not re-registered**: an A2 lesson's `grammar`/`lexicon`/`chunks` lists may contain A1 IDs, shown on the key-phrases screen as "From A1" and extended by the lesson. Duplicates are merged into one record, reused by ID. Records merged away lose their IDs (no learner progress exists on A2).~~

| Unit | New in A2 | Reviewed (A1 or earlier A2) |
|---|---|---|
| U1 Life Now | Present simple vs continuous (routine vs temporary; state verbs *like/want/know* not in *-ing*); follow-up questions incl. *How long / How often* | Present simple, present continuous, *do/does/be* questions, *and/but/because* (A1) |
| U2 Past Experiences | *was/were*; past simple regular (incl. the three *-ed* sounds); common irregular verbs; *did* questions/negatives; *ago / last / yesterday*, *finally / later* | *first / then / after that* (A1) |
| U3 People & Relationships | *look like / be like*; comparatives; superlatives; *someone who…*; *too / also* | *and / but* (A1) |
| U4 Home & Neighbourhood | *there was/were*; *(not) as…as* (replaces `A2.G.HOUSING_COMPARATIVES`); *too* + adj / adj + *enough*; *a lot of / much / many* (one record, absorbs U5's two); *Could you…?* requests (one record) | Comparatives (U3); *there is/are*, place prepositions (A1) |
| U5 Food & Services | *a few / a little*; containers and portions (*a bottle of, a slice of, a piece of*) | Imperatives, object pronouns, *I'd like / Can I have* (A1); *much/many* (U4); requests (U4) |
| U6 Travel Plans | *will* for decisions/offers; future forms compared; first conditional (the only record — U11 reuses it); *when / after / before* + present | *going to*, present continuous for arrangements (A1-U12) |
| U7 Health | *have to / don't have to* (the only record — U8 reuses it); *must / mustn't*; *to* + verb for purpose (the only record); "I've had it for…" as a fixed phrase | *should* (A1 chunk → full pattern), imperatives (A1) |
| U8 Work & Study | *could* for past ability; manner adverbs; verb + *-ing* / *to*; **present perfect for experience** (*ever / never*); formal request phrases (*Could you tell me…? Is it possible to…?*) | *have to*, purpose (U7) |
| U9 Technology | Zero conditional; *it / this / that / they* reference; "What happens when…?" | Imperatives, sequencing (A1/U5); present perfect "I've tried…" (U8) |
| U10 Stories | Past continuous; *when / while* with past simple; *who / which / that*; *although* | Present perfect "Have you seen…?" (U8); verb + *-ing* (U8) |
| U11 Nature & Problems | *will / may / might* for predictions and possibility; *someone / anything / nowhere…*; suggestions (*could, Let's, Why don't we…?*) | First conditional (U6); *because / so* (A1) |
| U12 Invitations & Events | **present perfect with *just / already / yet***; accepting/declining with reasons; *however / instead / unfortunately* | *Would you like to…?* (A1); future forms (U6); requests (U4) |

About 45 new A2 grammar records (reference: 72). Each record gets bilingual examples.

### Vocabulary

- About **35 new senses per unit** (~420 total). Every listed word appears in its lesson's conversation or text and is practised in at least one activity.
- **Superseded 2026-09-20:** the 30 A1-duplicating senses are **deleted**, not referenced. A word A1 already teaches is not listed by an A2 lesson at all; it may still appear in an A2 text. A genuinely new sense stays as an A2 record (A1 *change* = the verb, A2 *change* = the noun). Three were removed in the pilot — *routine*, *stay*, *busy*.
  - Why the reference approach was dropped: its only functional gain was enrolling A1 words into spaced review for a learner placed straight into A2, and this app's placement test never places anyone beyond A1. The only way into A2 without A1 is the lock sheet's "Open anyway", a deliberate "I already know this". Meanwhile every normal learner would get a **second** review row for a word they have known for months, on a fresh schedule, with their real history stranded on the A1 record the A2 lesson did not point at (`enrollLesson` leaves already-scheduled rows untouched, so the duplicate schedules independently).
- Examples are bilingual `{en, ar}` (A1's stay English-only strings).

## Design 2 — lesson design

### Unit shape (unchanged from A1)

7 lessons (L1–L5 guided, L6 model text, L7 mission); 36 activities; 6 `encounter` / 12 `practice` / 18 `mastery`.

### Guided lesson (L1–L5)

1. **Conversation** (`encounter.dialogue`): 2–3 named speakers, 4–8 lines, Arabic for every line; models the lesson's grammar and words.
2. **Key phrases + grammar note** (existing screen; A1 items marked "From A1").
3. **Warm-up** (`encounter`): a gist question on the conversation — not a second copy of its text.
4. **Practice** (2 `practice` activities), chosen for the target: form (gap, order), meaning (question→answer, sentence halves, choose the right form). English↔Arabic matching at most once per unit.
5. **Use it** (2 `mastery` activities): one receptive item on **new** input, then one speaking, writing or mediation task.

L6 (`integrated-production`): a lesson-level `readingText` `{title, text, textAr}` model text → questions on it → the learner writes their own.

### Length bands

| | A1 end | U1–U4 | U5–U8 | U9–U12 |
|---|---|---|---|---|
| Listening (dialogues/announcements), words | ~11 | 30–60 | 50–90 | 70–120 |
| Reading (lesson `readingText`), words | ≤44 | 60–100 | 90–140 | 120–180 |
| Writing (`wordGuide`) | 55–75 | 55–75 | 65–85 | 75–100 |

Single-question notices/messages (`sourceText`): 15–60 words.

### Skill balance per unit

Listening ≥10, reading ≤12, speaking (interaction + production) 6–8, writing 3, mediation 2. No prompt more than 3 times per unit.

### Speaking and mediation

- `speak` activities may carry `partnerTurns: [string]`, read aloud by TTS before the learner answers. The model treats A1's existing `examinerTurns` as the same field.
- Every mediation task (and every productive task that refers to material) carries `sourceCard: string` — the notice, timetable, profiles or listing — shown as a card.
- Every `mastery` speak/write activity carries a structured `keywordChecklist` `EvaluationSpec` (with `onlineRefinement: "grammarCheck"` for open paragraphs, as in A1). Speak fallbacks keep `fallbackSkill: "writing"`, `fallbackCountsFor: "accessOnly"`.

### Evidence tagging

Each A2 activity's `canDo` lists only the objectives its skill evidences (LISTENING/READING/PRODUCTION/INTERACTION/WRITING/MEDIATION by the objective ID's category; mission `ACTION.*` objectives accept any skill). Lessons keep their full `canDo` list.

### Missions and capstones

- Keep the 12 unit-mission scenarios and the 6-activity mission shape; inputs are new texts, never reused from the unit.
- Final Mission "Host a Visitor" and the Final Assessment (18/18/2/4/2) keep their design; every input is unseen; all source cards and partner turns supplied.
- Final Assessment writing tasks: 70–90 words.
- **Final Assessment pass mark: 0.6 per skill, Final Mission `minimumCriterionScore` 0.6** — A1's values; the reference's 0.75 is not adopted for either, for the same reason (keyword-only marking; both levels' exits should mean the same thing). Unit mastery stays 0.75.

## Design 3 — app

Unit/lesson/activity/registry IDs are globally unique by prefix (`A1-U3`, `A2.LEX…`), so existing progress needs no data migration.

### Content loading

- `kLevelCatalog` (`lib/content/catalog/level_catalog.dart`) gets A2's `bundleAssetPath` and an app-owned `prerequisiteLevelId: 'a1'`. A2's availability is a locked preview until release (see Lock). A `--dart-define` flag makes A2 fully available in development builds for the pilot.
- Every level with a bundle loads at startup, each parsed off the UI isolate as today.
- `CourseContentIndex.build` accepts the prerequisite level's index, so A2's A1 references resolve and `_validateReferences` checks them.
- The router gate (`app_router.dart`, `content_load_refresh_listenable.dart`) gates on A1 only. A2 failing to load marks A2 unavailable; the app carries on with A1.
- A **cross-level lookup** (unit, lesson, activity, lexicon, chunk, grammar by ID) is used by every screen that opens a specific item: unit overview, lesson player, lesson review, word/chunk/grammar detail, review session, quick practice, the refinement drain (`online_refinement_providers.dart`).

### Current level and lock

- Stored in Drift on `course_enrolments` (schema v5, two nullable columns): `lastSelectedAt` (current level = the enrolment selected most recently; default A1) and `unlockedAt`. `resetProgressForLearner` already deletes enrolments, so a reset returns the learner to A1 with A2 locked again.
- `ensureA1Enrollment` becomes enrolment-on-demand per level.
- **Level complete** = every unit that counts towards the level's mastery is mastered, **or** the level's Final Assessment is passed.
- **Soft lock (after release):** A2 is open when A1 is complete, or `unlockedAt` is set (by a placement result in A2 or by "Open A2 anyway"). Tapping locked A2 explains that A2 builds on A1 and offers **Take the placement test** / **Open A2 anyway**.
- **Locked preview (before release):** A2 appears in the switcher with a lock; its unit titles and topics are browsable; lessons don't open; no "Open anyway".

### Tabs

- **Learn:** A1 | A2 switcher at the top of `CourseScreen`; choosing a level makes it current; B1–C2 stay in "Coming later". Unit routes unchanged.
- **Home:** Continue card and progress card follow the current level. When the current level is complete and the next is released, Home suggests "Start A2" — never switches automatically.
- **Review:** due words/phrases from every level; weak spots across every level with units in progress, labelled by level.
- **Vocabulary / Grammar:** open on the current level with an A1 / A2 filter; grouped by unit.
- **Tests:** placement covers every released level; Final Mission and Final Assessment follow the current level.

### Rendering (also fixes A1)

- `textChoice.sourceText` shown with the question (A1's 27; all of A2's).
- Lesson `readingText` shown before the L6 activities. A1's 11 truncated `textAr` stubs are completed in the same step.
- `sourceCard` shown on any activity that has one.
- `partnerTurns` / `examinerTurns` read aloud before recording.
- Key-phrases screen marks A1 references "From A1".
- `lessonTypeLabel` covers `integrated-production`.

### Content model and wording

- `LexiconItem.examples` accepts strings or `{en, ar}` objects.
- `Unit.countsTowardA1Mastery` becomes a level-neutral field, reading `countsTowardA1Mastery` or `countsTowardA2Mastery`.
- Every "A1" in ARB copy takes the level as a parameter; new strings (switcher, lock sheet, "From A1", "Start A2", A2 placement results) written natively in Arabic and English.

## Design 4 — placement

1. **Block pass** over released levels in order — A1: U0–U3, U4–U6, U7–U9, U10–U12; A2: U1–U3, U4–U6, U7–U9, U10–U12. One item per unit in the block (3–4 per block), drawn from practice-mode listening/reading items, seeded per attempt. A block passes at ≥60% (`PlacementScoring.minimumScoreRatio`).
2. **Drill-down** in a failed block: its units in order, up to 3 items each (today's per-unit rule), stopping at the first failing unit, which is the recommendation. If every unit passes, continue with the next block.
3. One unscored productive item from the last unit reached (as today).
4. Test mode, `sessionType='placement'`, never mastery evidence (unchanged).

Approximate lengths: complete beginner ~7 items; gap at A1-U8 ~16; gap at A2-U5 ~25; all of A2 known ~25.

Outcomes (level derived from the unit ID): start with English Essentials (`A1-U0`); start A1 from the beginning; start A2 from the beginning; start at a specific unit (`A1-U2`…`A2-U12`); "{top released level} looks mastered" — never a claim above the top released level. The result offers "Start at …"; tapping it makes that level current, unlocks it and opens the unit. Stored outcomes from before this change (`a1Mastered` etc.) stay readable in history.

## Design 5 — workflow, quality checks, order of work

### Content workflow

1. **One-off import** of the reference into `assets/content/en/A2/a2-course-bundle.json`: keep IDs, convert copied A1 senses to A1 references, merge duplicate grammar records, set a new `contentVersion`.
2. **Rewrite unit by unit in that file** to Designs 1–2.
3. Arabic is written as natural Arabic, never word-for-word translation. A native speaker checks the pilot unit's Arabic before the batches.
4. At release, `reference/a2-modular-course/` gets an `OUT_OF_DATE.md` like A1's.

### Quality checks (Dart tests, `test/content/a2_*`)

Run over a list of finished units that grows with each batch:

- **Structure:** parses; all references resolve (incl. A1 references); IDs unique across A1 + A2; 7 lessons / 36 activities / 6-12-18 per unit.
- **Bilingual:** no empty Arabic (dialogue lines, prompts, registries, texts); no Arabic in English prompts.
- **Answerable:** every reading question has its text; every mediation task (and productive task that refers to material) has a `sourceCard`; every `mastery` speak/write activity has a non-null `EvaluationSpec`; every listed lesson word appears in its lesson; no A1 sense re-registered.
- **Design limits:** listening ≥10 / reading ≤12 per unit; length bands; `wordGuide` within band; no prompt >3× per unit; English↔Arabic matching ≤1 per unit; Final Assessment items not reused from lessons; activity `canDo` categories match its skill.
- **Masterable:** answering every `mastery` item correctly masters the unit — one test over all finished A2 units (A1 needed 13 files).
- **Release rule:** A2 can't be marked available in `kLevelCatalog` unless all 12 units, the Final Mission and the Final Assessment are on the finished list.

App work is covered by its own tests: cross-level lookup, current level, locks, block placement, the newly rendered fields, the schema v5 migration (`test/data/local/database_test.dart` pattern).

### Order of work (each step gets its own implementation plan)

1. **App foundations:** model/parser changes, prerequisite-aware index, cross-level lookup, rendering fixes (+ A1 `readingText` Arabic). — **Done**, `feature/a2-foundations`.
2. **Multiple levels:** current level, switcher, locked preview, soft lock, tabs, wording, placement. — **Done.** Step 2a (current level, switcher, locks, Learn tab) landed on `feature/a2-current-level`. **Step 2b landed in five parts on `feature/a2-pilot-u1`:** Tests and both capstones follow the current level, and so does Home — whose "Start A2" suggestion is built exactly as designed below (offered when the level is complete and the next is released, tapped by the learner, never automatic). Vocabulary and Grammar follow it too, with the level filter (`LevelFilterChips`), which is a view and never calls `select`; Vocabulary deliberately stays a flat searchable list rather than gaining the unit grouping the Tabs line below asks for, since its search and status filters are what a lookup list is for. The Review tab is built, to the line above: due words and phrases from every level the learner has reached, weak spots from every level with a unit in progress, each labelled by level. The block placement test landed last, to Design 4 exactly — blocks of three (four for A1, whose starter unit joins the opening block), one item per unit, drill-down into a failed block only, and a result that can make A2 current and unlock it. Two things the design did not say, decided while building it and worth carrying to B1: a drill-down excludes the item its block pass already asked (the per-unit shuffle is seeded, so it simply hands back the next items), and a "mastered" outcome is stored per level (`a1Mastered`, `a2Mastered`) rather than as one level-neutral name, so a result recorded when A1 was the only released level can never be re-read as a claim about a level that shipped later. Of the ARB wording, only `settingsProfileMeta` still says "A1".
3. **Import** the A2 reference (locked preview; full in development builds). — **Done**, commit `141e182`.
4. **Pilot:** rewrite A2-U1; product owner review in the app, including the Arabic; adjust design/tests. — **Done**, `feature/a2-pilot-u1`. The review changed two things recorded above as "Superseded 2026-09-20": A2 stopped referencing A1 ids at all, and the duplicated A1 senses were deleted rather than referenced.
5. **Batches:** U2–U4, U5–U7, U8–U10, then U11–U12 + Final Mission + Final Assessment. — **Done**, same branch, though not in those groupings: units were authored in the order U1, U3+U4, U2, U5, U6, U7, U10, U8, U11, U12, U9, then the Final Assessment and the Final Mission, each in its own commit.
6. **Release:** A2 available (soft lock), reference marked out of date. — **Done**, commit `ba2a73f`; `reference/a2-modular-course/OUT_OF_DATE.md` added with the docs pass.

### Documentation (part of each step's definition of done)

New ADR (multiple levels: current level, cross-level references, level locks). Updates to PRODUCT.md (A2 in scope), ROADMAP.md (A2 in progress; correct the "no new app mechanics" claim), ARCHITECTURE.md, DATA_MODEL.md (schema v5, A2 bundle, cross-level references), GLOSSARY.md (Current level, Level lock, "From A1" reference, placement blocks), UX_PRINCIPLES.md (lock copy), TESTING.md (A2 content tests).

## Carried forward from step 1 (landed 2026-09-20, branch `feature/a2-foundations`)

Two things the step-1 execution decided that later steps must honour:

- **The A2 content tests (step 3) must also fail a present-but-non-String bilingual field** (`ar`, `textAr`, `sourceText`), alongside the "no empty Arabic" rule. Step 1 unified four blank-to-null normalizations onto one `nonBlank(Object?)` helper (`lib/content/models/non_blank.dart`), which returns null for a non-String where two of those sites previously threw a `TypeError` at parse time. The looser parse is accepted deliberately — it matches how the content layer already degrades optional fields — so the strictness moves to the content tests instead.
- **Each step's plan must derive its documentation list from this section plus CLAUDE.md's Definition-of-done table**, not by hand. Step 1's plan omitted ROADMAP.md and the whole-branch review caught the stale "no new app mechanics required" claim still standing.

## Non-goals

- Re-tagging A1 activities' `canDo` lists (limitation 3) — a separate follow-up.
- B1+ content, or any placement result above the top released level.
- Rendering A1's `randomScenarioBank` (`A1-FINAL-ASSESS-S03`).
- Changing mastery rules, the grading approach (keyword checklists + optional LanguageTool), or unit-level recommendation-only progression.
- Regenerating A2 through the reference's `tools/authoring` generator.

## What actually shipped (recorded 2026-09-21, after release)

Verified against `assets/content/en/A2/a2-course-bundle.json` and the import at commit `141e182`, not against this document.

**Held exactly.** Unit shape (12 units × 7 lessons × 36 activities, 6/12/18). Skill balance — every unit is 12 listening / 12 reading / 7 speaking / 3 writing / 2 mediation, tighter than the "≥10 / ≤12 / 6–8 / 3 / 2" this spec asked for. Conversations: all 60 guided lessons open on 5–8 lines and 2–3 speakers with Arabic on every line (the import: 72 single-line "Narrator" paragraphs, 38 with no Arabic). Length bands, exactly as tabled, including `wordGuide` 55–75 / 65–85 / 75–100. Capstones at 0.6 with unit mastery left at 0.75. Prompt repetition: the spec allowed three uses per unit; all 432 prompts are distinct (the import had 291 distinct in 432).

**Diverged, and why it matters to know.**

- **The grammar map above was written before anyone checked the import's registry.** It lists what each unit should teach, unit by unit, and never says that **the present perfect was absent from all 72 imported records** — in the level CEFR most defines by it. It is now `A2.G.PRESENT_PERFECT_EXPERIENCE` (U8-L2, *ever/never*) and `A2.G.PRESENT_PERFECT_JUST_ALREADY_YET` (U12-L3), both listed by three and two lessons respectively. Treat the table above as intent; the bundle is the record.
- **"About 45 new A2 grammar records" did not happen and was the wrong frame.** The import's records were largely kept and rewritten in place. Net: 72 → 74, with 8 added and 6 retired.
- **Consolidation went two deep, not three.** The first conditional had **two** import records (`FIRST_CONDITIONAL_INTRO`, `FIRST_CONDITIONAL_NATURE`), not three as commit `a0981c4`'s message says; they became one `A2.G.FIRST_CONDITIONAL`, now listed by six lessons across U6, U9, U11 and U12. `FUTURE_CONTRAST` + `FUTURE_EVENT_REVIEW` → `A2.G.FUTURE_FORMS_CONTRAST`. `WORK_HAVE_TO` → `HAVE_TO_OBLIGATION`, `PURPOSE_APPLICATION` → `INFINITIVE_PURPOSE`.
- **Two consolidations this spec asked for were not made.** `A2.G.PURPOSE_TECH` (U9-L6) still exists beside `INFINITIVE_PURPOSE`, although Design 1 calls the latter "the only record"; and `A2.G.HOUSING_COMPARATIVES` (U4) survived alongside both `COMPARATIVE_ADJECTIVES` (U3) and the new `AS_AS_COMPARISON`, although Design 1 says the new record replaces it. Neither is caught by any gate — the gates check reference resolution and uniqueness, not that two records teach the same thing.
- **Vocabulary landed on different arithmetic.** Not "~35 new senses per unit, ~420 total" but 35–43 words and phrases listed per unit (lexicon + chunks), 462 listings across the level, over registries of 305 senses and 145 chunks. 29 imported senses were deleted, 118 added.
- **`onlineRefinement` went much wider than "for open paragraphs, as in A1".** Every one of A2's 144 speak/write tasks carries it, plus 8 capstone tasks — where A1 marks 23, all `write`, none in its capstones. Consequence: a spoken answer's recognised text now goes to the public LanguageTool API on the same bounded path. Unreviewed and undecided; recorded in [SECURITY.md](../../SECURITY.md)'s "Data handling".
- **The bundle's `contentVersion` is still `A2-IMPORT-2026.09.20`.** Design 5's import step said to set a new one and nothing bumped it as the level was written, so the string names the file's origin rather than its contents. `course_enrolments.contentVersion` snapshots it, so changing it later is not free.
- **Arabic was never read by a native speaker.** Design 5 step 3 required a native-speaker check of the pilot unit's Arabic before the batches; that did not happen, and units 3–12 were written by AI and machine-checked only for presence and script. The gates can prove a field contains Arabic and is not the English copied across; they cannot prove it reads naturally. Recorded in README's "Known limitations".
- **The gates grew a rule this spec didn't ask for**: a per-unit vocabulary floor of 30 words and phrases, added after a unit reached its full 36 activities while teaching a handful of senses. Nothing else counted what the activities were supposed to teach.

## Risks

- **Authoring volume:** ~84 lessons, ~420 words, ~44 grammar records, two capstones. The pilot exists to catch design problems before this scales.
- **Arabic quality:** written by the author, not a native speaker; mitigated by the pilot review.
- **Keyword-only marking** of longer A2 answers is coarse; the 0.6 Final Assessment pass mark and structured checklists keep it fair but not precise.
- **No real device** in this environment: multi-speaker TTS and partner turns are verified only through the speech-service fakes until a device build exists.
