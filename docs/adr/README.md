> **What this folder is:** One short record per significant decision — what was decided, what alternatives were considered, and why. This is the project's *governance* trail: it stops the same debate from being silently re-litigated in a future session.
> **How to use it:** Copy [0000-template.md](0000-template.md) to `NNNN-short-title.md` (next sequential number) whenever a decision is hard to reverse, non-obvious, or was debated. Skip it for routine/reversible choices. Never edit or delete a past ADR to reflect a new decision — add a new ADR that supersedes it and note the link both ways.

_Last verified: 2026-09-02 — added ADR 0004, which supersedes ADR 0001 for the v1 timeframe._

# Architecture Decision Records

| # | Title | Status |
|---|---|---|
| [0001](0001-offline-first-firebase-only-backend.md) | Offline-first architecture with Firebase as the only backend | Accepted (superseded for v1 by [0004](0004-local-only-v1-no-firebase-backend.md)) |
| [0002](0002-flutter-for-cross-platform-mobile.md) | Flutter for cross-platform mobile (iOS + Android) | Accepted |
| [0003](0003-on-device-speech-writing-assessment-for-mvp.md) | On-device speech/writing assessment for MVP; cloud AI grading deferred | Accepted |
| [0004](0004-local-only-v1-no-firebase-backend.md) | Local-only v1 — zero Firebase, no accounts, content shipped as a bundled asset | Accepted |
