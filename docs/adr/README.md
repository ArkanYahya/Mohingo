> **What this folder is:** One short record per significant decision — what was decided, what alternatives were considered, and why. This is the project's *governance* trail: it stops the same debate from being silently re-litigated in a future session.
> **How to use it:** Copy [0000-template.md](0000-template.md) to `NNNN-short-title.md` (next sequential number) whenever a decision is hard to reverse, non-obvious, or was debated. Skip it for routine/reversible choices. Never edit or delete a past ADR to reflect a new decision — add a new ADR that supersedes it and note the link both ways.

_Last verified: 2026-09-22 (`feature/bundled-audio`) — added ADR 0008 (speech audio is pre-generated at authoring time with Kokoro and bundled per level; the device engine is only a fallback). Earlier the same day (`feature/level-standard-and-content-versioning`) — added ADR 0007 (one standard for every level: one gate suite over a per-level config, permanent published ids, vocabulary self-contained and grammar inheritable, A1 brought up to it). Previously verified 2026-09-20 (`feature/a2-foundations`) — added ADR 0006 (multiple levels: a current level, earlier-level references, level locks) and backfilled the missing ADR 0005 row. Previously verified 2026-09-02 — added ADR 0004, which supersedes ADR 0001 for the v1 timeframe._

# Architecture Decision Records

| # | Title | Status |
|---|---|---|
| [0001](0001-offline-first-firebase-only-backend.md) | Offline-first architecture with Firebase as the only backend | Accepted (superseded for v1 by [0004](0004-local-only-v1-no-firebase-backend.md)) |
| [0002](0002-flutter-for-cross-platform-mobile.md) | Flutter for cross-platform mobile (iOS + Android) | Accepted |
| [0003](0003-on-device-speech-writing-assessment-for-mvp.md) | On-device speech/writing assessment for MVP; cloud AI grading deferred | Accepted |
| [0004](0004-local-only-v1-no-firebase-backend.md) | Local-only v1 — zero Firebase, no accounts, content shipped as a bundled asset | Accepted |
| [0005](0005-narrow-network-exception-for-open-ended-grading.md) | A narrow, bounded network exception for open-ended answer grading | Accepted |
| [0006](0006-multiple-levels.md) | More than one level — a current level, earlier-level references, and level locks | Accepted |
| [0007](0007-one-standard-for-every-level.md) | One standard every level is held to, enforced by one suite | Accepted |
| [0008](0008-bundled-pre-generated-speech-audio.md) | Speech audio is pre-generated at authoring time and bundled, not synthesized on the device | Accepted |
