> **What this file is:** The chosen technologies and the reasoning behind each choice — not just *what* we use but *why*, and what we deliberately didn't pick.
> **How to use it:** Check before adding a new library/framework/service. If something isn't listed, it isn't approved yet — raise it for discussion rather than adding silently. A stack change belongs here *and* as an entry in [adr/](adr/).

_Last verified: 2026-09-01 — initial stack decisions established via brainstorming session._

# Tech Stack

## Frontend

- **Framework:** Flutter (Dart) — why: single codebase for iOS + Android, strong built-in RTL support (needed for Arabic UI), good offline-first story.
- **State management:** Riverpod — standard, testable state management for Flutter.
- **Alternatives considered:** React Native/Expo — would let logic share with a JS/TS backend, but the app has no custom backend (see below), so that advantage doesn't apply here; Flutter's RTL support tipped the decision.

## Backend

- **Language / framework:** None — the app is offline-first with no custom backend server. Firebase is used as a Backend-as-a-Service (BaaS) instead of a hand-rolled API.
- **Alternatives considered:** Python/FastAPI, Node.js/TypeScript — rejected; a maintained server isn't needed for a solo, offline-first app, and adds operational burden with no corresponding benefit at this stage.

## Database

- **Local (on-device):** Drift (SQLite-based) — stores bundled/downloaded lesson content (units, exercises) and offline progress/scores; relational and queryable, needed since content and progress are structured.
- **Cloud (sync):** Firestore — cross-device progress sync and content distribution (the app downloads lesson content from Firestore/Cloud Storage rather than bundling all of it at install time).
- **Alternatives considered:** Isar, Hive — considered for local storage; Drift chosen for its relational/SQL querying, which fits structured curriculum data better than a pure key-value/NoSQL local store.

## Infrastructure / hosting

- **Hosting:** Firebase (Auth, Firestore, Cloud Storage) — no servers to provision or maintain.
- **CI/CD:** TBD — to be decided when the build/release process is set up (likely Codemagic or GitHub Actions for Flutter builds).

## Third-party services

| Service | Purpose | Notes |
|---|---|---|
| Firebase Auth | User accounts / sign-in | |
| Firestore | Cross-device progress sync; content distribution (app downloads lesson content from here) | |
| Firebase Cloud Storage | Lesson audio files (listening exercises, pronunciation examples) | |
| Platform speech-to-text (`speech_to_text` package, wrapping iOS/Android native engines) | On-device speaking assessment | Offline, no API cost |
| LLM API (e.g. Claude) | Content generation — used in the offline dev-time authoring pipeline only, not called by the shipped app | You review/edit AI output before it's published to Firestore/Storage |

## Explicitly rejected

| Option | Reason rejected |
|---|---|
| Custom backend server (Python/FastAPI or Node.js) | Not needed for a solo, offline-first app; Firebase covers the actual requirements (auth, sync, storage) without server upkeep. |
| Cloud-based AI grading for speaking/writing at runtime | Conflicts with "fully offline" requirement for MVP; deferred to post-MVP roadmap (see [ROADMAP.md](ROADMAP.md)) once a serverless AI-grading path (e.g. Firebase Cloud Functions) is worth the added complexity. |
| React Native/Expo | Flutter's RTL support and single-codebase story fit better; no backend exists to share TypeScript types with. |
