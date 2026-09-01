> **What this file is:** The entities, their relationships, and the constraints that matter (uniqueness, ownership, required fields). Keeps the schema's intent legible even as migrations accumulate.
> **How to use it:** Update when an entity or relationship changes. If migration files exist, treat them as the literal source of truth and keep this as the readable summary + rationale.

_Last verified: 2026-09-01 — initial data model established via brainstorming session._

# Data Model

Stored across two places: **Drift (local/SQLite)** holds the learner-facing copy of published content plus all progress data, and is the source of truth for what the app renders. **Firestore** holds the authoring/publishing side (all `ContentItem` statuses) and is the sync target for progress across devices — the app only ever downloads `published` content from it.

## Entities

### Learner

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK, matches Firebase Auth UID | |
| nativeLanguage | enum | fixed to `ar` for MVP | not user-editable in MVP |
| targetLanguage | enum | fixed to `en` for MVP | not user-editable in MVP |
| currentLevelId | FK → Level | | assigned by placement test |
| createdAt | timestamp | | |

### Level

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK, e.g. `a1` | |
| cefrCode | enum | one of A1/A2/B1/B2/C1/C2 | only `a1` populated in MVP |
| order | int | | for sequencing |

### Block

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK | |
| levelId | FK → Level | required | |
| order | int | 1–4 for A1 | the 4 thematic blocks |
| title | string (bilingual) | required | stored as `{ar, en}` |

### Unit

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK | |
| blockId | FK → Block | required | |
| order | int | | |
| title | string (bilingual) | required | |

### Exercise

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK | |
| unitId | FK → Unit | required | |
| skill | enum | one of vocabulary/grammar/reading/listening/writing/speaking | |
| order | int | | |
| content | JSON | required | shape varies by skill (prompt, options, audio ref, etc.) |
| explanation | string (bilingual) | optional | contrastive Arabic/English grammar/vocab notes |

### Attempt

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK | |
| learnerId | FK → Learner | required | |
| exerciseId | FK → Exercise, nullable | one of exerciseId or unitId set | exercise-level attempt |
| unitId | FK → Unit, nullable | one of exerciseId or unitId set | unit-assessment attempt (gates progression) |
| result | enum | pass/fail | |
| score | float, nullable | | |
| takenAt | timestamp | | |

### ContentItem

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | string | PK | wraps a Unit or Exercise during authoring |
| targetType | enum | unit/exercise | |
| targetId | string | | |
| status | enum | draft / approved / published | only `published` is ever downloaded by the app |
| generatedBy | string | | e.g. LLM model/version used |
| reviewedBy | string, nullable | | the author, once reviewed |

## Relationships

One Level has many Blocks. One Block has many Units. One Unit has many Exercises. One Learner has many Attempts (one per exercise taken, plus one per unit-assessment taken). One ContentItem wraps exactly one Unit or Exercise as it moves through the authoring workflow.

## Key constraints & invariants

- A Unit is considered "passed" for a Learner when a passing `Attempt` exists with `unitId` set to that unit.
- A Block completes when all its Units are passed; a Level completes when all its Blocks complete.
- Only `ContentItem`s with `status = published` are ever synced to a device — `draft`/`approved` content never reaches the app.
- `nativeLanguage`/`targetLanguage` are fixed (`ar`/`en`) for the MVP; the schema allows other values so this isn't a hard rewrite later, but no UI exists to change them yet.

## Migration source

None yet — Drift schema/migrations will live under `lib/data/local/` once implementation starts (see [ARCHITECTURE.md](ARCHITECTURE.md)); this doc is authoritative until then.
