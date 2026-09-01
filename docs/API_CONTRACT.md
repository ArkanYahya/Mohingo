> **What this file is:** The source of truth for what the API looks like from the outside — endpoints, request/response shapes, status codes. Prevents the frontend and backend (or different sessions working on either) from silently diverging.
> **How to use it:** Update *before or alongside* changing an endpoint, not after. If the project adopts a formal schema (OpenAPI/GraphQL SDL), that generated/authored file becomes the real source of truth — keep this doc as a human-readable index pointing to it.

_Last verified: 2026-09-01 — initial contract established via brainstorming session; adapted for a Firestore-backed app (no custom REST/GraphQL API — see [ARCHITECTURE.md](ARCHITECTURE.md) and [TECH_STACK.md](TECH_STACK.md))._

# API Contract

There is no custom server API. The app talks directly to Firebase (Auth SDK + Firestore SDK + Cloud Storage SDK). This doc plays the same role an OpenAPI spec would: the source of truth for the client-facing data contract — collection paths, document shapes, and access rules — until Firestore Security Rules files exist, at which point those become the enforced source of truth and this stays as the human-readable index.

## Schema source of truth

This document, until `firestore.rules` and `storage.rules` files exist in the repo (not yet created).

## Conventions

- Access: via Firebase SDKs (Auth, Firestore, Cloud Storage), not HTTP endpoints — no base URL/versioning in the REST sense.
- Auth: Firebase Auth ID token, attached implicitly by the SDK; enforced server-side via Firestore/Storage Security Rules (not yet written).
- Errors: surfaced as Firebase SDK exceptions (e.g. `FirebaseException` with a `code`), handled client-side per [CONVENTIONS.md](CONVENTIONS.md).
- "Pagination": Firestore query cursors (`startAfter`/`limit`), used where a collection could grow large (e.g. `attempts`).

## Collections

| Path | Purpose | Access |
|---|---|---|
| `/learners/{learnerId}` | Learner profile (native/target language, currentLevelId) | Read/write: owning learner only |
| `/learners/{learnerId}/attempts/{attemptId}` | Exercise/unit-assessment attempts (progress data) | Read/write: owning learner only |
| `/levels/{levelId}` | Published Level metadata | Read: any authenticated learner. Write: none from client (published by the content-authoring tool via admin credentials) |
| `/levels/{levelId}/blocks/{blockId}` | Published Block metadata | Read: any authenticated learner. Write: none from client |
| `/levels/{levelId}/blocks/{blockId}/units/{unitId}` | Published Unit metadata | Read: any authenticated learner. Write: none from client |
| `/levels/{levelId}/blocks/{blockId}/units/{unitId}/exercises/{exerciseId}` | Published Exercise content | Read: any authenticated learner. Write: none from client |
| `/contentItems/{contentItemId}` | Authoring-side draft/approved/published tracking (see [DATA_MODEL.md](DATA_MODEL.md)) | Not accessible to the app at all — written only by the content-authoring tool via admin credentials |

## Cloud Storage

| Path pattern | Purpose | Access |
|---|---|---|
| `/audio/{levelId}/{unitId}/{exerciseId}.mp3` | Listening-exercise / pronunciation-example audio | Read: any authenticated learner. Write: none from client |
