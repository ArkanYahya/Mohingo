> **What this file is:** The high-level shape of the system — layers, boundaries, data flow, folder structure. The single biggest lever for keeping AI sessions from drifting, since most inconsistency comes from this not being written down.
> **How to use it:** Read before adding a new module or changing how data flows. If a change alters this shape, update the diagram/description *and* record the reasoning as an [ADR](adr/).

_Last verified: 2026-09-02 — rescoped for the local-only, zero-Firebase v1 decided this session (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)); added the `lib/content/` module and the curriculum-bundle content-loading flow, grounded in the actual A1 bundle at `docs/a1-modular-course/dist/a1-course-bundle.json`._

# Architecture

## Overview

Mohingo v1 is a fully local, offline Flutter mobile client (iOS + Android) with **no backend at all** — not even for auth. A separate, non-shipped dev-time tool (`docs/a1-modular-course/`) handles AI-assisted content authoring: an LLM drafts lesson content, the author reviews/edits it, and the curriculum package's own build tooling produces one runtime bundle (`dist/a1-course-bundle.json`) that is copied into the Flutter app as a bundled asset — not downloaded from anywhere. Firebase (Auth, Firestore, Cloud Storage) as a Backend-as-a-Service, and account-based cross-device progress sync, are both deferred to a later phase — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md), which supersedes [ADR 0001](adr/0001-offline-first-firebase-only-backend.md) for the v1 timeframe.

## Layers / boundaries

```
UI (widgets)
  -> state (Riverpod providers/notifiers)
    -> repository layer
      -> local data (Drift/SQLite) — progress only, the source of truth for what the app renders
      -> remote data (Firestore / Cloud Storage) — NOT IMPLEMENTED in v1; interfaces exist as a
         future-sync seam only (see "Repositories and future sync" below), no class calls out to it
```

A separate, third data source sits alongside the two above: **bundled curriculum content** (`lib/content/`), loaded once from a Flutter asset and held in memory — never mirrored into Drift. See "Content module" below.

A separate on-device **speech service** (native TTS/STT) is called directly from lesson-player/vocabulary/grammar features via its own DI-bound interface — it doesn't go through the repository/data layers since it's a device capability, not persisted content.

Rules for crossing layers:
- UI never talks to Drift, the content asset, or (later) Firestore directly — always through a repository or the content-index provider. This keeps local-vs-remote swappable and the UI testable against a fake repository.
- The local database (Drift) is the source of truth for *progress*; the parsed content bundle is the source of truth for *curriculum content*; the two are never merged into one store, and Drift only ever references the bundle's stable string IDs (never duplicates bundle content).

## Folder structure

```
lib/
  core/            # theme (ColorScheme/ThemeExtension), router (go_router), l10n wiring,
                    #   media (diagram renderers for the curriculum's structured scene types),
                    #   shared widgets (loading/empty/error/unsupported-content states), utils
  content/         # bundled curriculum ONLY — read-only, never mutated, never imported by data/local
    models/          # typed immutable models (freezed) for the bundle's shape: units, lessons,
                      #   activities (9 types), grammar/lexicon/chunk registries, media specs,
                      #   final mission, final assessment, domain definitions (skills/modes/canDo/policy)
    parsing/         # CourseBundleParser + schemaVersion/contentVersion validation
    index/           # CourseContentIndex — id -> object maps, built once at startup
    catalog/         # app-owned level-availability table (A1 = available, A2-C2 = comingSoon)
    providers/       # Riverpod providers exposing the loaded bundle + index, kept alive app-lifetime
  data/
    local/           # Drift schema (progress tables only), DAOs, migrations
    remote/          # EMPTY in v1 — future-sync seam only, no implementation registered
  features/
    <feature>/
      presentation/  # widgets, screens
      application/   # Riverpod providers/notifiers
      domain/        # entities, business rules
      data/          # feature-specific repository implementations (local-backed in v1)
```

Feature areas: `app_shell, onboarding, course_catalog, learning_path, lesson_player, activity_engine, vocabulary, grammar, review, placement_test, final_mission, final_assessment, progress, speech, settings`. `course_catalog` (generic: which levels exist/are available) is kept distinct from `learning_path` (A1-guided-path-specific screen logic) — this split is what makes adding an A2 bundle later purely additive, with zero changes to A1 code.

## Repositories and future sync

Every progress-relevant repository interface (e.g. `MasteryEvidenceRepository`) is written today as if a remote counterpart already existed: progress records carry an app-level `uuid`, `updatedAt`, and `deletedAt` (soft-delete marker) even though v1 never reads them. Only one implementation exists in v1 (`Drift...Repository`), bound via Riverpod. Adding sync later means writing a *new* implementation and swapping the provider binding — no caller, and no domain-layer code, needs to change.

## Key flows

**Content (author → learner, v1):** dev-time curriculum pipeline runs in `docs/a1-modular-course/` → LLM drafts lesson content → author reviews/edits → curriculum's own validators/build tool (`validate-a1.mjs`, `audit-quality.mjs`, `build-a1.mjs`) produce `dist/a1-course-bundle.json` → that file is copied verbatim into the Flutter project as an asset (`assets/content/en/A1/a1-course-bundle.json`) → at app startup, parsed once off the UI isolate, `schemaVersion` validated, indexed into `CourseContentIndex` → lessons render from that in-memory index. No network call is involved anywhere in this flow after the app is installed. (Deferred, post-v1: replacing the "copied at build time" step with a Firestore-hosted download-on-launch step, per [ADR 0001](adr/0001-offline-first-firebase-only-backend.md)'s original longer-term direction.)

**Progress (learner, v1):** learner completes an activity → written to local Drift immediately, insert-only (a replay appends a new attempt row rather than overwriting, so mastery history survives revisits) → a `MasteryAggregationService` recomputes cached per-unit/per-objective state from the evidence rows. No sync step exists in v1 — progress never leaves the device. (Deferred, post-v1: a background push to Firestore when a connection is available, enabling cross-device resume, once accounts exist.)

## Cross-cutting concerns

- **Auth:** none in v1 — no accounts, no sign-in. A single local `Learner` profile is created on first launch, identified by a locally-generated stable UUID (not a Firebase Auth UID). See [SECURITY.md](SECURITY.md) and [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Deferred, post-v1: Firebase Auth, once account sync is built.
- **Error handling:** typed exceptions thrown from the repository/content-parsing layers, caught and translated to user-facing messages at the UI layer — see [CONVENTIONS.md](CONVENTIONS.md). An unsupported/corrupted content bundle produces a typed `UnsupportedContentSchemaException`/`ParseError`, routed to a dedicated "unsupported content" screen, never a raw crash.
- **Logging / observability:** no analytics or crash-reporting SDK in v1 (decided this session — see [ROADMAP.md](ROADMAP.md)); answers, personal text, and speech transcripts are never logged in release builds regardless.
- **Config / secrets:** LLM API keys used for content generation live only in the separate dev-time authoring tool and are never bundled into the shipped app. No Firebase config is bundled in v1 (there is no Firebase SDK usage at all).

## Deployment topology

Mobile app distributed via the Apple App Store and Google Play. **No hosted infrastructure of any kind in v1** — no server, no Firebase project. The content-authoring tool runs locally on the author's machine, not deployed anywhere; its output is copied into the app repo as a versioned asset at build time. (Deferred, post-v1: a Firebase project, once account sync is built.)
