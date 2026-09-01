> **What this file is:** The high-level shape of the system — layers, boundaries, data flow, folder structure. The single biggest lever for keeping AI sessions from drifting, since most inconsistency comes from this not being written down.
> **How to use it:** Read before adding a new module or changing how data flows. If a change alters this shape, update the diagram/description *and* record the reasoning as an [ADR](adr/).

_Last verified: 2026-09-01 — initial architecture established via brainstorming session._

# Architecture

## Overview

Mohingo is an offline-first Flutter mobile client (iOS + Android) backed by Firebase as a Backend-as-a-Service — there is no custom server. A separate, non-shipped dev-time tool handles AI-assisted content authoring: an LLM drafts lesson content, the author reviews/edits it, and approved content is published to Firestore/Cloud Storage. The app downloads and caches that content locally so lessons work fully offline after the initial sync.

## Layers / boundaries

```
UI (widgets)
  -> state (Riverpod providers/notifiers)
    -> repository layer
      -> local data (Drift/SQLite)
      -> remote data (Firestore / Cloud Storage), used for sync only
```

A separate on-device **speech service** (native speech-to-text) is called directly from the speaking-exercise feature — it doesn't go through the repository/data layers since it's a device capability, not persisted content.

Rules for crossing layers:
- UI never talks to Drift or Firestore directly — always through a repository. This keeps local-vs-remote swappable and the UI testable against a fake repository.
- The local database (Drift) is the source of truth for what the app renders; Firestore is a sync target/source, not read directly by the UI.

## Folder structure

```
lib/
  core/            # shared utilities: theming, RTL/LTR helpers, localization (ar/en)
  features/
    <feature>/
      presentation/  # widgets, screens
      application/   # Riverpod providers/notifiers
      domain/        # entities, business rules
      data/          # feature-specific repository implementations
  data/
    local/           # Drift schema, DAOs
    remote/          # Firestore/Cloud Storage clients
```

## Key flows

**Content (author → learner):** dev-time pipeline runs → LLM drafts lesson content → author reviews/edits → published to Firestore/Cloud Storage → app checks for new/updated content on launch (when online) → downloads and caches into Drift → lessons render from the local cache thereafter, working fully offline.

**Progress (learner → sync):** learner completes an exercise → written to local Drift immediately (works offline, no network dependency) → background sync pushes to Firestore when a connection is available → enables cross-device resume.

## Cross-cutting concerns

- **Auth:** Firebase Auth (detail in [SECURITY.md](SECURITY.md))
- **Error handling:** typed exceptions thrown from the repository layer, caught and translated to user-facing messages at the UI layer — see [CONVENTIONS.md](CONVENTIONS.md)
- **Logging / observability:** TBD — not yet decided
- **Config / secrets:** LLM API keys used for content generation live only in the separate dev-time authoring tool and are never bundled into the shipped app. Firebase config is bundled per standard Flutter/Firebase setup (not treated as secret, per Firebase's own model).

## Deployment topology

Mobile app distributed via the Apple App Store and Google Play. No server deployment — Firebase project (Auth, Firestore, Cloud Storage) is the only hosted infrastructure. The content-authoring tool runs locally on the author's machine, not deployed anywhere.
