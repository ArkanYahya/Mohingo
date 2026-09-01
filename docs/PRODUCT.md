> **What this file is:** The definition of what the app is, who it's for, and what counts as "done." Prevents scope from being reinvented differently in each session.
> **How to use it:** Update when scope actually changes (a feature is added/cut/reprioritized). Keep it at the level of *what and why*, not *how* — implementation belongs in [ARCHITECTURE.md](ARCHITECTURE.md).

_Last verified: 2026-09-01 — initial product definition established via brainstorming session._

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
- Unit-by-unit progress gating (must pass a unit's assessment to advance)

### Explicitly out of scope (for now)

- Monetization / payments (no paid tiers, subscriptions, or ads)
- Social / community features (no leaderboards, friends, sharing, forums)
- Teacher / classroom tools (no assigning content or tracking groups of students)
- Any taught language other than English
- Any native/interface language other than Arabic and English
- CEFR levels beyond A1 (A2–C2 are roadmapped, not built, in the MVP)

## Success criteria

The MVP is "done" when all A1 content and mechanics are built and functional: all 4 thematic blocks, all 4 skills, the placement test, bilingual UI/explanations, and unit progress gating all work end-to-end. This is a feature-completeness bar, not a pedagogical-outcomes bar — it is not gated on real learners completing the level yet.

## Key user flows

1. **Onboarding** — learner signs up, selects Arabic as native language, and is introduced to the app in bilingual UI.
2. **Placement test** — learner takes a short test; MVP always confirms/assigns A1 as the starting level.
3. **Level overview** — learner sees the A1 level broken into its 4 thematic blocks and the units within each.
4. **Unit lesson flow** — within a unit: vocabulary (with bilingual glosses) → grammar instruction (bilingual explanation) → guided practice/drills → reading passage → listening exercise → writing task → speaking task → end-of-unit assessment.
5. **Progress gating** — passing a unit's assessment unlocks the next unit; a block completes when all its units are passed.
6. **Level completion** — after all 4 blocks are passed, the learner completes CEFR level A1.
7. **Progress tracking** — learner can see their position within A1 (blocks/units completed, skills practiced) at any time.

## Open questions

- How is speaking practice actually assessed (automated pronunciation/fluency scoring vs. simpler recording-and-self-check)? To be resolved in TECH_STACK.md / ARCHITECTURE.md.
- How is writing practice graded (rules-based checks vs. AI-graded free text)? To be resolved in TECH_STACK.md / ARCHITECTURE.md.
- What does the content review workflow look like in practice (queue, approval states, versioning)? To be resolved in DATA_MODEL.md / ARCHITECTURE.md.
- Post-MVP: will additional native languages (beyond Arabic) ever be supported, or is the bilingual Arabic/English design permanent? Affects how hard-coded vs. localizable the UI layer should be.
