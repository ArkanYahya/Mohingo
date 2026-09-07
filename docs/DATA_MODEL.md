> **What this file is:** The entities, their relationships, and the constraints that matter (uniqueness, ownership, required fields). Keeps the schema's intent legible even as migrations accumulate.
> **How to use it:** Update when an entity or relationship changes. If migration files exist, treat them as the literal source of truth and keep this as the readable summary + rationale.

_Last verified: 2026-09-08 — full rewrite grounded in the actual A1 curriculum bundle (`docs/a1-modular-course/dist/a1-course-bundle.json`) and the local-only v1 decision; see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). The old Learner/Level/Block/Unit/Exercise/Attempt/ContentItem model predated inspection of the real curriculum data and is superseded by this document. Phase 7 confirmed the `vocabulary_review_state` columns against a real SM-2 implementation, not just reserved them. Phase 9 confirmed `placement_attempts`/`final_mission_attempts`/`final_assessment_attempts` against real read/write usage (no schema change needed) and fixed a real latent bug in their "most recent attempt" queries: ordering by `startedAt` alone ties when two attempts start within the same clock tick (a fast retake); a stable `id DESC` tiebreaker was added to all three. Phase 10: documented the structured `EvaluationSpec` shape and nullable `Learners.name` column. 2026-09-08: `EvaluationSpec` moved to `lib/content/models/` (it is pure bundle data, so the content layer owns it) and `fromJson` now degrades a malformed-but-recognized spec to `null` instead of throwing.

# Data Model

Two entirely separate stores, per [ARCHITECTURE.md](ARCHITECTURE.md), never merged:

- **Content** — the curriculum bundle (`assets/content/en/A1/a1-course-bundle.json` in v1), parsed into typed immutable models and indexed in memory at startup. Read-only at runtime; the app never writes to it. Described in "Content entities" below.
- **Progress** — local Drift (SQLite) tables, the source of truth for everything the app renders about a learner's state. Described in "Progress entities (Drift)" below. Content-reference columns in these tables (`unitId`, `activityId`, `canDoId`, etc.) store the bundle's stable string IDs **directly** — Drift never mirrors or duplicates content.

There is no cloud store in v1 (no Firestore) — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md).

## Content entities (bundle-sourced, read-only)

Field lists below are the subset that matters for app logic, not an exhaustive schema — the bundle is the literal source of truth for exact shape.

### Course

One per level bundle (only `a1` exists in v1). `id` (e.g. `"EN-A1-V2"`), `title`/`titleAr`, `contentVersion` (e.g. `"A1-COMPLETE-2026.09.02"`), `schemaVersion`, `finalMissionId`, `finalAssessmentId`.

### Unit

`id` (e.g. `"A1-U1"`), `title`/`titleAr`, `levelRole`, `estimatedMinutes: [min,max]`, `countsTowardA1Mastery`, `lessons: [Lesson]`, `mastery: {requiredObjectives: [canDoId], requiredSkillGroups: [[skill]], minimumObjectiveScore, missionRequired, retry}`. **There is no Block entity** — A1 is 13 flat units (`A1-U0`…`A1-U12`); "Block" is superseded, see [GLOSSARY.md](GLOSSARY.md).

### Lesson

`id` (e.g. `"A1-U1-L1"`), `title`/`titleAr`, `lessonType`, `canDo: [canDoId]`, `grammar`/`lexicon`/`chunks: [registryId]` (the items this lesson introduces or draws on), optional `encounter: {dialogue: [{speaker, en, ar}]}`, `activities: [Activity]`.

### Activity

Discriminated by `type` — one of `audioChoice`, `textChoice`, `match`, `order`, `gap`, `form`, `speak`, `write`, `dialogue` (the last declared in `domain.ACTIVITY_TYPES` but with no authored instances yet in the current bundle). Common fields: `id`, `mode` (`encounter`/`practice`/`mastery`), `skill`, `canDo: [canDoId]`, `prompt`/`promptAr`. Type-specific fields (e.g. `options`/`answer` for choice types, `pairs` for `match`, `accepted`/`fallbackSkill` for `speak`, `evaluation`/`wordGuide` for `write`; `evaluation` is a structured `{type, ...}` object — one of `nonEmpty`, `numericRange`, `letterSequence`, `keywordChecklist` — parsed by `EvaluationSpec.fromJson` in `lib/content/models/evaluation_spec.dart`, or `null` for content not yet migrated off the legacy opaque rubric-name string **and** for a recognized `type` whose required fields are missing or wrong-typed — an authoring error degrades to one un-auto-graded activity, never a throw that `CourseBundleParser` would turn into a whole-bundle `ContentParseException`; see docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md) vary per type — see the content-model layer for the exact typed shape per type.

### Grammar / Lexicon / Chunk (registries)

- **Grammar**: `id` (e.g. `"A1.G.BE.I_AM"`), `form`, `shortForm`, `meaningAr`, `introducedIn` (lessonId), `examples: [{en, ar}]`.
- **Lexicon**: `id`, `headword`, `partOfSpeech`, `arabic`, `receptive`/`productive` (bool), `meaning`, `examples: [string]`, `introducedIn`, `recycledIn: [lessonId]`. Two records may share a `headword` while being distinct senses (e.g. `A1.LEX.PICTURE.N01` vs `N02`) — always keyed and treated by `id`, never by spelling.
- **Chunk**: `id`, `text`, `arabic`, `introducedIn`, `productive`, `recycledIn`.

### Media specification

Keyed by a string id (either a standalone scene id or a `ttsSource`'s own key). Two kinds:
- **`ttsSource`**: `{locale, voiceProfile, transcript, activityId}` — read aloud by on-device TTS at runtime; no pre-recorded audio file exists anywhere in the bundle.
- **Structured scene types** (`peopleCard`, `personCard`, `peopleMap`, `homePlan`, `objectScene`, `distanceScene`, `apartmentPlan`): data describing a diagram to render (e.g. `{people: [{id, role}], links: [[id, id, relation]]}`), not artwork — rendered by app-owned diagram widgets, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Final Mission / Final Assessment

- **`FinalMission`**: `id` (`"A1-FINAL-MISSION"`), `scenario`, `canDo: [canDoId]` (EXIT_* ids), `stages: [{id, activityIds}]`, `activities: [Activity]`, `scoring: {completionRequired, requiredSkillGroups, criteria, minimumCriterionScore, speechAccuracyWeight, noSingleAverageCompensation}`.
- **`FinalAssessment`**: `id` (`"A1-FINAL-ASSESSMENT"`), `sourcePolicy` (secure/unseen inputs), `sections: {listening, reading, writing, speaking, mediation}` (each with its own `activities`), `scoring` per-section (e.g. `speaking: {criteria, minimumTaskCriterionAverage, minimumCompletedTasks, accuracyWeight}`, plus `decisionRule: {noSingleOverallAverage, required: [skill], capstoneMissionRequired}` and `accessibility: {microphoneFallback: "writing", fallbackDoesNotCreateSpeakingEvidence: true}`).

### Domain definitions

`SKILLS` (6 values: `listening`, `reading`, `writing`, `spokenInteraction`, `spokenProduction`, `mediation`), `MODES` (`encounter`/`practice`/`mastery`), `ACTIVITY_TYPES` (9 values, see Activity above), `CAN_DO` (flat map of ~90 objective ids), `MASTERY_POLICY` (`minimumObjectiveScore: 0.75`, `minimumEvidencePerRequiredObjective: 2`, `requireProductiveEvidenceWhereDeclared: true`, `practiceCountsAsMastery: false`, `allowSpeechFallbackToWriting: true`, `speechCriteria`, `speechAccuracyWeight: 0.2`).

### Content catalogue

Not part of the bundle — a small, app-owned static table mapping `levelId` (`a1`..`c2`) to `LevelAvailability` (`available`/`comingSoon`) and, when available, the asset path to load. Only `a1` is `available` in v1.

## Progress entities (Drift, local, source of truth for learner state)

Every table has a local autoincrement `id` (SQLite-internal only, never exposed outside the DB layer) **and** a separate `uuid TEXT UNIQUE` column (app-level stable identity, for a future sync layer — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)). These are distinct concerns and are never conflated.

### learners

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | int | PK, autoincrement | local row identity only |
| uuid | string | UNIQUE | replaces the old Firebase-Auth-UID identity — generated locally on first launch |
| nativeLanguage | enum | fixed to `ar` for MVP | not user-editable in MVP |
| targetLanguage | enum | fixed to `en` for MVP | not user-editable in MVP |
| createdAt | timestamp | | |
| isActive | bool | | v1 never exposes profile switching; kept as a real table, not a single-row blob, so a future multi-profile/sync-merge scenario needs no schema change |
| name | string | nullable | the learner's own name, set via Settings; used only by the `letterSequence`/`profileName` evaluation reference (see the Activity section above), never required for anything else. |

### course_enrolments

`id`, `uuid`, `learnerId` FK, `courseId` (bundle `course.id`, e.g. `"EN-A1-V2"`), `contentVersion` (bundle `contentVersion` at enrolment time — anchors "which content version was this progress recorded against"), `enrolledAt`, `status`.

### unit_progress

`id`, `uuid`, `learnerId`, `unitId` (string, bundle id), `state` (`notStarted`/`inProgress`/`needsReview`/`mastered`), `lastActivityAt`, `masteredAt`, `isContentStale`, `updatedAt`. **A read-model** — recomputed by a `MasteryAggregationService` from `activity_attempts`/`activity_attempt_can_dos`, cached here for fast Home/Learn queries; never hand-edited directly by a UI action.

### lesson_progress

`id`, `uuid`, `learnerId`, `lessonId`, `unitId` (denormalized), `state`, `lastActivityId` (resume pointer, written after every meaningful event — not just at lesson end), `lastPositionUpdatedAt`, `updatedAt`.

### activity_attempts

`id`, `uuid`, `learnerId`, `activityId` (string, bundle id — or the mission/assessment item's own id namespace), `lessonId` (nullable — null for placement/mission/assessment items), `sessionType` (`lesson`/`practiceReview`/`placement`/`finalMission`/`finalAssessment`), `sessionId` (nullable, links to the relevant attempt table's `uuid`), `mode` (`encounter`/`practice`/`mastery`, copied at record time so history stays self-describing even if content changes later), `evidenceSkill`, `rawAnswer` (JSON), `isCorrect`, `score`, `criteriaScores` (JSON), `wasFallback`, `attemptedAt`, `updatedAt`. **Insert-only, never updated** — a replayed activity appends a new row rather than overwriting, so a learner revisiting a completed unit never corrupts prior mastery history.

`evidenceSkill` normally equals the activity's declared `skill`; when a `speak` activity is answered via its bundle-declared `fallbackSkill: "writing"`, `wasFallback=true` and `evidenceSkill='writing'` are written at record time — this is the concrete mechanism implementing the bundle's own `fallbackDoesNotCreateSpeakingEvidence` rule (present on `finalAssessment.scoring.accessibility` and mirrored for unit/mission `speak` activities).

### activity_attempt_can_dos

`id`, `attemptId` FK, `canDoId` (string). Normalizes an activity's `canDo: [id]` array into one row per (attempt × canDo) pair, so mastery aggregation is a single indexed SQL `GROUP BY canDoId, evidenceSkill` join rather than per-row JSON scanning in Dart.

### placement_attempts / final_mission_attempts / final_assessment_attempts

Each holds one row per attempt at that assessment (`id`, `uuid`, `learnerId`, `startedAt`, `completedAt`, plus an outcome summary specific to that assessment type — e.g. `placement_attempts.outcome` is one of the four actionable A1-only outcomes, never a fabricated A2+ level). Per-item results for all three live in `activity_attempts`, filtered by `sessionType`. Kept as separate attempt tables (not folded into `course_enrolments`) so retakes are isolated and item-answer state never leaks into ordinary lesson Review — see [ARCHITECTURE.md](ARCHITECTURE.md).

### vocabulary_review_state

`id`, `uuid`, `learnerId`, `lexiconId` (nullable) or `chunkId` (nullable, exactly one set), `isFavorite`, `confidenceMarker`, `easeFactor`, `intervalDays`, `repetitions`, `dueAt`, `lastReviewedAt`, `updatedAt`. Created lazily on first favourite/review-queue encounter, not pre-populated for all ~500 lexicon+chunk records at enrolment. `easeFactor`/`intervalDays`/`repetitions`/`dueAt` are computed by a genuine SM-2 (SuperMemo-2) scheduler (`SpacedReviewScheduler`) driven by a simplified 3-button Again/Good/Easy confidence input — see its doc comment for the exact formula. This schedule is vocabulary-memory only; it never grants or affects Can-Do mastery, which lives entirely in `activity_attempts`/`unit_progress` instead.

### grammar_review_state

`id`, `uuid`, `learnerId`, `grammarId`, `isFavorite`, `markedReviewedAt`, `updatedAt`. `markedReviewedAt` is a UI-only checkbox — it never flips any Can-Do objective's mastered state.

### content_versions

`id`, `contentVersion`, `schemaVersion`, `courseId`, `installedAt`, `unitIdsJson`, `lessonIdsJson`, `activityIdsJson`, `canDoIdsJson`. Append-only log of every bundle version loaded on-device; the id-set snapshots (not the full bundle) are what makes detecting removed ids possible when content updates later, without re-parsing history.

### Device/UI preferences — deliberately not in this list

Theme mode, colour theme, interface language, text scale, TTS voice/rate/pitch, and the "seen onboarding" flag live in `shared_preferences`, not Drift — see [TECH_STACK.md](TECH_STACK.md). Keeping them out of Drift means "reset progress" in Settings can never accidentally also reset a learner's language/theme.

## Relationships

One `Course` (bundle) has many `Unit`s; one `Unit` has many `Lesson`s; one `Lesson` has many `Activity`s. `Lesson`s and `Activity`s reference `Grammar`/`Lexicon`/`Chunk` registry items and `CAN_DO` objective ids by string id — never by duplicating the referenced record.

One `learners` row has many `course_enrolments`, `unit_progress`, `lesson_progress`, `activity_attempts` (across all `sessionType`s), `placement_attempts`, `final_mission_attempts`, `final_assessment_attempts`, `vocabulary_review_state`, and `grammar_review_state` rows. One `activity_attempts` row has one-to-many `activity_attempt_can_dos` rows (mirroring the source activity's `canDo` array at attempt time).

## Key constraints & invariants

- **Content and progress never mix.** No Drift table stores curriculum text/prompts/options; no content model stores a learner's answers. Content-reference columns store bundle string ids verbatim.
- **Mastery is per-`(canDoId, evidenceSkill, mode)`, not a single score.** A Can-Do objective is "mastered" per `MASTERY_POLICY`: enough `mode='mastery'` evidence rows (`minimumEvidencePerRequiredObjective`), each meeting `minimumObjectiveScore`, with productive evidence present where the unit's `requiredSkillGroups` declare it required. `practiceCountsAsMastery` is always `false` — `mode='practice'` rows are never counted. A learner who can recognise language but not produce it must not show as fully mastered — see [PRODUCT.md](PRODUCT.md) and the curriculum's own non-negotiable rule (`docs/a1-modular-course/README_AR.md`).
- **Attempts are insert-only.** Revisiting a completed unit/activity appends new `activity_attempts` rows; nothing is ever overwritten or deleted, so mastery history is always reconstructable. The one deliberate exception is a learner explicitly choosing "Reset progress" in Settings (`AppDatabase.resetProgressForLearner`) — a confirmed, destructive, learner-initiated action (see [UX_PRINCIPLES.md](UX_PRINCIPLES.md)'s confirmation-copy rule) that deletes every progress/attempt/review row for that learner across every table listed here, while leaving the `learners` row itself (and its uuid) untouched — it resets progress, not identity.
- **A speaking fallback never creates speaking evidence.** Encoded at write time via `evidenceSkill`/`wasFallback`, not derived at read time — see `activity_attempts` above.
- **Assessment inputs stay isolated from training.** `placement`/`finalMission`/`finalAssessment` attempts are never surfaced through ordinary Review screens, which query `activity_attempts` filtered to `sessionType='lesson'` only.
- **A Unit's progression is a recommendation, not a hard lock.** `unit_progress.state` drives the "Continue learning" suggestion and unit badges; it never blocks navigation to another unit — see [PRODUCT.md](PRODUCT.md) flow 5 and [ARCHITECTURE.md](ARCHITECTURE.md)'s navigation guards.
- `nativeLanguage`/`targetLanguage` are fixed (`ar`/`en`) for the MVP; the schema allows other values so this isn't a hard rewrite later, but no UI exists to change them yet.
- **No PII beyond what's listed in [SECURITY.md](SECURITY.md)** is ever written to `activity_attempts.rawAnswer` at rest for speaking activities — raw audio/transcripts are never persisted, only minimal derived scoring data.

## Migration source

None yet — Drift schema/migrations will live under `lib/data/local/` once implementation starts (see [ARCHITECTURE.md](ARCHITECTURE.md)); this doc is authoritative until then. `schemaVersion` starts at 1; Drift's stepwise `MigrationStrategy` (`onUpgrade`) is the mechanism for all future changes, with schema-export/verification tooling adopted from the first implementation phase even though v1 ships only one schema version.
