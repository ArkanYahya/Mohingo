# 0006: More than one level — a current level, earlier-level references, and level locks

**Status:** Accepted

## Context

The app was built for A1 alone. An A2 curriculum (from `reference/a2-modular-course/`) is being adapted to continue it — see docs/superpowers/specs/2026-09-19-a2-level-design.md. A2 has to feel like the next stage of the same course: its lessons review A1 language, a learner's A1 words keep coming up for review while they study A2, and a learner who already knows A1 must be able to start A2 without being blocked. The A2 reference also re-registered 30 A1 words and several A1 grammar points under new A2 ids, which breaks the curriculum's own rule ("reuse the id, never copy the record").

## Decision

1. **Levels are one journey with a current level.** The learner works in one current level (stored with their progress, so "Reset progress" returns them to A1). Home and Tests follow it; Review is shared across levels; Vocabulary and Grammar open on it with a filter.
2. **A level may build on an earlier one.** The app-owned catalogue declares `prerequisiteLevelId` (A2 → A1). The earlier level loads first and the later level's index is built with it attached, so a lesson may list the earlier level's grammar, word and phrase ids — shown to learners as "From A1". Bundles stay self-contained files; the dependency lives in the catalogue.
3. **Items open in their own level.** Every bundle id starts with its level (`A1-U3`, `A2.LEX…`); a screen that opens one item finds the level from the id.
4. **Levels lock softly.** Before a level is released it is a locked preview (titles and topics browsable, lessons closed). After release A2 opens once A1 is complete, after a placement result in A2, or when the learner chooses "Open A2 anyway". Units within a level stay recommendation-only.

## Alternatives considered

- **Separate courses per level** (switching level switches the whole app, Review included) — rejected: A1 words would stop being reviewed exactly when A2 starts relying on them.
- **Strict order (A2 only after A1 is finished)** — rejected: contradicts "recommend, never lock", and would block adults who already know A1.
- **Copying A1 records into the A2 bundle** — rejected: two ids for one sense, two review schedules for one word.
- **One merged bundle for all levels** — rejected: larger startup cost and every level's edits in one file; the catalogue already makes levels additive.

## Consequences

- A2's index depends on A1's: if A1 fails to load, A2 does too (A2 failing never takes A1 down).
- Ids must keep their level prefix; a test fixture without one can't be opened by id.
- Later levels (B1+) reuse the same mechanism: each declares the level it builds on.
