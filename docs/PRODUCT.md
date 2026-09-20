> **What this file is:** The definition of what the app is, who it's for, and what counts as "done." Prevents scope from being reinvented differently in each session.
> **How to use it:** Update when scope actually changes (a feature is added/cut/reprioritized). Keep it at the level of *what and why*, not *how* — implementation belongs in [ARCHITECTURE.md](ARCHITECTURE.md).

_Last verified: 2026-09-20 (`feature/a2-current-level`) — corrected "CEFR levels beyond A1 are roadmapped, not built": A2's content now ships inside the app as a not-yet-released level — its units are browsable, its lessons aren't — while B1–C2 remain roadmapped only; see [ADR 0006](adr/0006-multiple-levels.md) and [ROADMAP.md](ROADMAP.md). Also noted that flow 5's "recommend, never block" principle now extends to levels, not just units. Previously verified 2026-09-09 — onboarding and progress-gating flows updated for the local-only, free-access v1 decided this session; see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Phase 10 corrected stale "progress gating" wording in Success criteria (the actual v1 model is recommendation-only, per flow 5) and resolved 3 of the 4 Open questions below against what actually got built. Added flow 4's read-only lesson-answer-review step (Learn tab only) — see docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md._

# Product

## Problem

Self-directed adult learners whose native language is Arabic need a structured way to learn English — one that follows the same logical, level-by-level progression as established resources (e.g. Oxford), rather than disconnected practice or drilling. Mohingo provides that structure, organized around the CEFR scale (A1 through C2).

## Target users

Self-directed adult learners, native Arabic speakers, learning English on their own (not in a classroom, not assigned by a teacher). The product is designed to eventually serve the full CEFR range (A1–C2); the MVP targets learners starting from zero (A1).

## Scope

### In scope (MVP)

- Full CEFR A1 level content (~70–100 guided-learning-hours worth), organized into the standard thematic blocks:
  1. Alphabet, pronunciation, numbers, greetings
  2. Personal information, classroom language, basic nouns
  3. Present simple verbs, basic questions, common adjectives
  4. Short reading texts, simple writing tasks, listening to slow speech
- All 4 CEFR skills: reading, listening, writing, speaking
- A placement test (confirms/assigns starting level; MVP only has A1 to place into)
- Bilingual Arabic/English UI (all app chrome — navigation, buttons, instructions)
- Bilingual explanations for grammar/vocabulary (contrastive notes — e.g. explaining how an English structure differs from the Arabic equivalent)
- RTL (Arabic) + LTR (English) layout support throughout
- AI-generated lesson content, curated and reviewed before publishing (content pipeline: generate → review → publish)
- A recommended unit-by-unit path with mastery tracking (not a hard lock — see key user flow 5)

### Explicitly out of scope (for now)

- Monetization / payments (no paid tiers, subscriptions, or ads)
- Social / community features (no leaderboards, friends, sharing, forums)
- Teacher / classroom tools (no assigning content or tracking groups of students)
- Any taught language other than English
- Any native/interface language other than Arabic and English
- CEFR levels beyond A1 as something a learner can actually study — A2's content is in the app as a not-yet-released level (its units are browsable, but its lessons stay closed until release, see [ADR 0006](adr/0006-multiple-levels.md) and [ROADMAP.md](ROADMAP.md)); B1–C2 remain roadmapped, not built

## Success criteria

The MVP is "done" when all A1 content and mechanics are built and functional: all 4 thematic blocks, all 4 skills, the placement test, bilingual UI/explanations, and unit progress tracking (recommendation-based, never a hard lock — see flow 5) all work end-to-end. This is a feature-completeness bar, not a pedagogical-outcomes bar — it is not gated on real learners completing the level yet.

## Key user flows

1. **Onboarding** — learner creates a local profile (no account/sign-up in v1 — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)), selects Arabic as native language, and is introduced to the app in bilingual UI.
2. **Placement test** — learner takes a short test; MVP always confirms/assigns A1 as the starting level.
3. **Level overview** — learner sees the A1 level broken into its 4 thematic blocks and the units within each.
4. **Unit lesson flow** — within a unit: vocabulary (with bilingual glosses) → grammar instruction (bilingual explanation) → guided practice/drills → reading passage → listening exercise → writing task → speaking task → end-of-unit assessment. Reopening a lesson that's already reached its final activity (Learn tab only) shows a read-only review of the learner's latest answer to each activity first — correct/incorrect, and the correct answer where one exists — rather than dropping back into a blank replay; an explicit "Practice again" button is the only way from there into a full live replay, which still appends fresh evidence rather than overwriting history (see [DATA_MODEL.md](DATA_MODEL.md)). The Tests tab's own retake flows (Final Mission, Final Assessment, the Placement Test) are unaffected — a separate, later decision.
5. **Progress tracking, not hard gating** — the app recommends the next unit via mastery evidence (per-CanDo-objective, tracked separately per skill — see [DATA_MODEL.md](DATA_MODEL.md)), but a learner may freely open any unit, vocabulary, grammar, review, or test screen at any time; a block completes when all its units are mastered. The same recommend-don't-block principle now extends to levels: a level the learner hasn't reached, or one the app hasn't released, explains why and offers a way forward (take the placement test, open it anyway, or just look at what it covers) rather than a dead end — see [UX_PRINCIPLES.md](UX_PRINCIPLES.md) and [ADR 0006](adr/0006-multiple-levels.md).
6. **Level completion** — after all 4 blocks are passed, the learner completes CEFR level A1.
7. **Progress tracking** — learner can see their position within A1 (blocks/units completed, skills practiced) at any time.

## Open questions

- ~~How is speaking practice actually assessed?~~ **Resolved**: on-device speech-to-text checks task completion only (never pronunciation/fluency scoring), with a typed-answer fallback that's always available and never recorded as speaking evidence — see [ADR 0003](adr/0003-on-device-speech-writing-assessment-for-mvp.md) and [TECH_STACK.md](TECH_STACK.md).
- ~~How is writing practice graded?~~ **Resolved**: rules-based exact/near-match checking against the bundle's own `accepted` answer list where one is declared; free-response items with no `accepted` list are recorded but reported honestly as not-yet-scored (`notAutoGraded`/"pending review") rather than guessed at — no AI-graded free text in v1, see [TECH_STACK.md](TECH_STACK.md)'s "Explicitly rejected" table.
- ~~What does the content review workflow look like in practice?~~ **Resolved**: the separate dev-time curriculum tool's own pipeline (LLM draft → author review/edit → `validate-a1.mjs`/`audit-quality.mjs`/`build-a1.mjs`) produces one versioned `dist/a1-course-bundle.json`, copied into the app as a static asset — no in-app review queue or approval states exist, since content authoring never happens on-device. See [ARCHITECTURE.md](ARCHITECTURE.md)'s content-loading flow.
- Post-MVP: will additional native languages (beyond Arabic) ever be supported, or is the bilingual Arabic/English design permanent? Affects how hard-coded vs. localizable the UI layer should be. Still open — no decision made this session.
