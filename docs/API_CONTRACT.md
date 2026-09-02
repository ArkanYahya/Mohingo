> **What this file is:** The source of truth for what the API looks like from the outside — endpoints, request/response shapes, status codes. Prevents the frontend and backend (or different sessions working on either) from silently diverging.
> **How to use it:** Update *before or alongside* changing an endpoint, not after. If the project adopts a formal schema (OpenAPI/GraphQL SDL), that generated/authored file becomes the real source of truth — keep this doc as a human-readable index pointing to it.

_Last verified: 2026-09-02 — marked N/A for v1: the app has zero Firebase usage and no accounts in v1 (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)), so there is no client-facing data-access contract to document yet. Kept as a placeholder for the post-v1 sync design._

# API Contract

**Not applicable for v1.** The app has no backend of any kind in v1 (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)) — no Firebase Auth, no Firestore, no Cloud Storage, no accounts. There is no client-facing data-access contract to define: the app's only two data sources are a bundled, read-only curriculum asset (see [ARCHITECTURE.md](ARCHITECTURE.md)'s `lib/content/` module and [DATA_MODEL.md](DATA_MODEL.md)) and a local Drift database, both fully described in those docs.

## When this doc becomes relevant again

Once account-based sync is built (see [ROADMAP.md](ROADMAP.md) and [ADR 0001](adr/0001-offline-first-firebase-only-backend.md), whose longer-term Firebase-as-backend direction still stands for that later phase), this doc should be rewritten to describe whatever data-access contract that sync layer exposes — Firestore collection paths and Security Rules if Firebase is still the choice at that point, or an equivalent for whatever's chosen instead. Until then, leave this doc as this placeholder rather than maintaining stale collection paths that don't correspond to anything the app does.
