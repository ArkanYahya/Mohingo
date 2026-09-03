> **What this file is:** The path from the MVP (CEFR A1) through the full vision (CEFR C2), plus the non-content features deferred out of the MVP. Prevents "start small" from losing sight of the full shape of the product.
> **How to use it:** Update when a phase completes or the plan changes. Each phase's content work follows the same pattern established for A1 in [PRODUCT.md](PRODUCT.md), [DATA_MODEL.md](DATA_MODEL.md), and [ARCHITECTURE.md](ARCHITECTURE.md) — this doc tracks *sequencing*, not re-deriving structure per level.

_Last verified: 2026-09-02 — added analytics/crash reporting and local backup export/import to the deferred list, decided this session; see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Phase 10 corrected a stale line in "Content phases" that still described publishing future levels to Firestore — future levels ship as bundled assets, same as A1, per the local-only v1 decision; bumped the MVP row's status to reflect Phases 3-9 being feature-complete._

# Roadmap

## Vision

A self-directed adult Arabic-speaking learner can go from zero English (A1) to full proficiency (C2), through the same structured, level-by-level, four-skill progression established for the MVP — offline-first, bilingual, on one app.

## Content phases (A1 → C2)

Guided-learning-hour figures below are cumulative, standard CEFR/Cambridge estimates (from zero) — a guideline for scoping each phase's content volume, not a commitment to exact numbers.

| Phase | CEFR level(s) | Cumulative guided hours (reference) | Status |
|---|---|---|---|
| MVP | A1 | ~70–100 | Feature-complete, Phase 10 (QA/performance/store-readiness/docs) in progress — see [PRODUCT.md](PRODUCT.md) and [CLAUDE.md](../CLAUDE.md) |
| Phase 2 | A2 | ~160–200 | Not started |
| Phase 3 | B1 | ~350–400 | Not started |
| Phase 4 | B2 | ~500–600 | Not started |
| Phase 5 | C1 | ~700–800 | Not started |
| Phase 6 | C2 | ~1,000–1,200 | Not started |

Each content phase repeats the same shape as A1: break the level into thematic blocks derived from CEFR "can-do" statements for that level, author blocks/units/exercises across all 4 skills through the AI-generate-then-review pipeline, and ship the result as a new bundled asset (`assets/content/en/A2/...`, etc.) the same way A1 ships — no Firestore, no network sync, per the local-only v1 decision (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)); `course_catalog`'s level-availability table is what makes adding a level purely additive. No new app mechanics required, just more content — until the deferred account-sync phase (item 8 below) changes this delivery mechanism.

## Non-content roadmap (deferred from MVP)

These were explicitly scoped out of the MVP (see [PRODUCT.md](PRODUCT.md)) and are revisited here as the product matures, roughly in this order:

1. **Cloud-based AI grading for speaking/writing** — replaces/augments the on-device speech-to-text + rule-based writing checks with real AI scoring (e.g. via Firebase Cloud Functions calling an LLM), once the offline-only approach's limitations are felt. See the "Explicitly rejected" note in [TECH_STACK.md](TECH_STACK.md).
2. **CI/CD pipeline** — formalize build/release automation (Codemagic or GitHub Actions) once release cadence increases.
3. **Monetization** — no plan yet; revisit once there's a working, validated product across more than one level.
4. **Social/community features** — streaks-with-friends, leaderboards, etc. — only after the core solo learning experience is proven.
5. **Teacher/classroom tools** — a different user (teacher) and data model (groups/assignments); treat as a distinct sub-project with its own brainstorming pass, not a bolt-on.
6. **Additional native languages beyond Arabic** — would require generalizing the currently-fixed `nativeLanguage`/`targetLanguage` fields (already schema-flexible, see [DATA_MODEL.md](DATA_MODEL.md)) into a real localization system, plus re-authoring contrastive explanations per language pair.
7. **Analytics and crash reporting** — no telemetry SDK ships in v1, to keep the app free of any required network call or third-party data collection while it's fully local. Revisit once there's a concrete question telemetry would answer.
8. **Account-based sync and local backup export/import** — v1 stores progress locally only, with no way to move it between devices or recover it after an uninstall (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)). A basic local export/import is the smaller near-term step; full account sync is the larger one, likely arriving together with item 1 above (both need the same account/backend groundwork).

## Open questions carried from PRODUCT.md

- Speaking/writing assessment quality is capped by the on-device/rule-based approach until non-content item 1 above is tackled — worth revisiting after A1 ships and real usage shows whether that's a real pain point.
- Whether additional native languages are ever supported (non-content item 6) affects how hard-coded the Arabic/English assumption stays in the meantime; not a blocker for A1–C2 content phases, which are English-content-only regardless.
