> **What this file is:** The one definition per domain term, so "Order" doesn't mean one thing in the API and another in the UI copy.
> **How to use it:** Before introducing a new domain noun (entity, status, role), check here first. If it's not here, add it the moment you name it in code.

_Last verified: 2026-09-01 — initial glossary established via brainstorming session._

# Glossary

| Term | Definition | Notes / not to be confused with |
|---|---|---|
| CEFR | Common European Framework of Reference for Languages — the 6-level scale (A1–C2) the app's curriculum is structured around. | |
| Level | A single CEFR level (e.g. A1). Contains 4 Blocks. | Not to be confused with "level" as a loose skill descriptor — it always refers to a CEFR level entity. |
| Block | A thematic sub-section of a Level (e.g. A1's "alphabet, pronunciation, numbers, greetings"). Contains multiple Units. | |
| Unit | A single lesson within a Block; the smallest gated progression step. Contains Exercises across skills. | |
| Exercise | One activity within a Unit, typed by Skill (vocabulary, grammar, reading, listening, writing, or speaking). | |
| Skill | One of the 4 CEFR competencies the app teaches: reading, listening, writing, speaking. | Vocabulary/grammar are exercise types, not one of the 4 CEFR skills, though they support all of them. |
| Can-do statement | CEFR's standard way of describing what a learner at a given level can actually do (e.g. "can introduce themselves"). Used as the basis for Unit objectives. | |
| Placement test | A short assessment at onboarding that assigns a Learner's starting Level. MVP always assigns A1. | |
| Attempt | A Learner's recorded result for either a single Exercise or a Unit's gating assessment. | |
| Learner | An app user — always a self-directed adult, native language Arabic, target language English for MVP. | Not "student" (implies classroom/teacher, which is explicitly out of scope). |
| Native language / Target language | The learner's own language (Arabic, fixed for MVP) vs. the language being learned (English, fixed for MVP). | |
| ContentItem | The authoring-side record tracking a Unit/Exercise through the content review workflow (draft/approved/published). | Not visible to Learners — authoring-only concept. |
| Content pipeline | The dev-time (non-shipped) process of generating lesson content via LLM and reviewing it before publishing. | Distinct from the app's runtime — the pipeline never runs on a learner's device. |
