# 0007: One standard every level is held to, enforced by one suite

**Status:** Accepted

## Context

By 2026-09-21 the app shipped two released levels and held them to different bars. A2's content was gated by 47 tests across seven hand-written files (`test/content/a2_*`), every rule written as A2-specific code over an A2-specific finished-units list. A1 — the level every new learner meets first — was gated by five tests and a set of per-unit regressions that check one unit can be mastered, not that it is well formed. Everything the A2 gates catch (a listening item with no transcript, a prompt with no Arabic, a speaking task nothing can grade, a unit that requires nothing of a skill it teaches) was unchecked on A1, and adding B1 would have meant writing every rule an eighth time, with the eighth copy drifting from the seventh in ways nobody would notice.

Two further facts were prose with nothing behind them. "Ids are stable across content versions" was asserted in DATA_MODEL.md and in a table comment, while `activity_attempts` stores `activityId`, `mode` and `canDoId` as plain strings with no foreign key — so a reused id re-attributes a learner's work, a changed `mode` re-counts it, and a dropped `canDo` strands it. And the content-versioning layer that was meant to notice content moving under a learner was fully implemented and had zero callers.

Running A2's gates over A1, once they were made level-agnostic, found roughly 290 content items A2 would have been refused for, and eight gate rules that compared a cruder key than the rule meant — a defect the suite had produced before, and one A2's own shape could never reveal.

## Decision

1. **One gate suite, every released level.** `test/content/levels/` holds the rules once; `test/content/levels/level_gate_config.dart` holds each level's numbers and finished-units list in a `LevelGateConfig`, and every gate file loops over `kLevelGates`. A level joins by adding a row. `level_config_test.dart` fails if a level is `available` in the catalogue with no row.
2. **A level's differences are declared exceptions, never skips.** A `DeclaredException` is a value plus a written reason; an excepted unit is still checked, against its own numbers, and the reason prints on failure. There is no boolean anywhere in the config that turns a gate off. A1 carries two shape exceptions (U0, U1) and its own balance, bands and tagging granularity, each because changing it would move a published id. A new level carries none.
3. **Published ids are permanent, `mode` frozen, `canDo` append-only**, enforced by a committed snapshot per level (`test/content/published/`) and a gate in three directions — stability, completeness, version — with a merge-only update script that refuses to record new ids under an unchanged `contentVersion`.
4. **A level is self-contained for vocabulary and may reference an earlier level's grammar.** Words and phrases a lesson lists must be the level's own; a grammar record may be inherited. `level_structure_test.dart` enforces both directions.
5. **`docs/LEVEL_STANDARD.md` is the standard.** Every rule in it names the test that enforces it, and adding a level costs a catalogue entry, a bundle, a config row and a snapshot — nothing in `lib/` and nothing else in `test/`.
6. **A1 was brought up to the standard rather than excused from it** (2026-09-22): roughly 290 additive changes, no id moved, no mode changed, no tag dropped, under a bumped `contentVersion`.

## Alternatives considered

- **Keep per-level suites** — rejected. It is how the gap between A1 and A2 arose, and B1 would have made it three suites drifting three ways.
- **Ratchet A1's defects instead of fixing them** — a committed, itemised list of every offender that may only shrink, with the gates failing on anything new. Honest and cheap, and it was offered; the product owner chose to fix everything, because 44 English-only prompts and 21 ungradeable speaking tasks in the first level a learner meets break rules CLAUDE.md lists as non-negotiable.
- **Re-tag A1's activities per skill so the per-activity Can-Do rule holds** — rejected. It would drop objectives from published activities, which the append-only policy forbids; the unit-level form of the rule is what the app's mastery model actually depends on.
- **Set A1's config so it passed as-is** — rejected. It would have meant declaring that an English-only prompt is acceptable at A1, which removes the signal rather than the defect.
- **Enforce id stability by convention** — rejected; that is what the project had.

## Consequences

- Adding B1 costs configuration, not code, and the standard says so with the file names that prove it. If a third level turns out to need a fifth step, that is a defect in the app or in the standard, and the standard is where to record it.
- A1 is now as gated as A2. Existing learners who had mastered A1-U2, U8, U11 or U12 will see the unit return to In progress until they evidence one newly required objective — carried by mastery activities they already did, so the next recompute after answering any of them — and the stale-unit line tells them why. That is the content-versioning feature (this branch) doing its job.
- Retiring content is deliberately harder: a published activity cannot be deleted, only repaired or superseded under a new id, and a content change must bump `contentVersion` or stale detection stays silent.
- The gate suite is itself a maintenance surface. Eight of A1's nineteen initial failures were the gates being wrong, all the same defect — comparing a cruder key than the rule means (`Skill.writing` for "free-writing task", `keywordChecklist` for "graded", every mode for "teaches", one placeholder notation for "template", a whole slash card for "one phrase"). A level whose content has a shape the current levels lack will find more of these; the fix is the key, never the threshold.
- Two A1 exceptions are permanent. Removing them would move published ids, which is a worse harm to a learner than a shorter first unit.
- Nothing here decides how content is delivered or whether it updates over the air. Both remain open ([ADR 0004](0004-local-only-v1-no-firebase-backend.md) for today's answer); the gates read a bundle wherever it lives.
