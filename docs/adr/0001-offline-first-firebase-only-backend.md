# 0001: Offline-first architecture with Firebase as the only backend

**Status:** Accepted

## Context

Mohingo is a solo-built CEFR English-learning mobile app for self-directed Arabic-speaking learners. A traditional client-server architecture (custom API backend + database) was the default assumption going into tech-stack planning. As a solo project, ongoing server operation (hosting, scaling, security patching, uptime) is a real cost with no corresponding product requirement — the core learning content doesn't need to be dynamic or real-time, and the target user may have inconsistent connectivity.

## Decision

The app is offline-first: lesson content is downloaded and cached locally (Drift/SQLite) and works fully without a network connection once synced. Firebase is used as a Backend-as-a-Service (Auth, Firestore, Cloud Storage) instead of a custom server — there is no backend codebase to build or operate. Firestore holds published content (synced down to the device) and learner progress (synced up when online); the local database is always the source of truth for what the app renders.

## Alternatives considered

- **Custom backend (Python/FastAPI or Node.js/TypeScript) + hosted database** — rejected. Adds a server to build, deploy, and maintain solo, with no feature in the MVP that actually requires server-side logic beyond what Firestore Security Rules can express (per-learner data isolation, read-only published content).
- **Firebase backend but online-only (no local cache)** — rejected. Conflicts with the "fully offline" requirement; a self-directed learner should be able to complete lessons without a reliable connection.

## Consequences

- Makes solo operation sustainable — no server to keep running, patched, or scaled.
- Makes true offline use possible, which is core to the product's usability for the target user.
- Forecloses (for now) any feature that genuinely needs server-side compute at request time — e.g. cloud-based AI grading of speaking/writing must go through a serverless path (Firebase Cloud Functions) rather than a general-purpose backend; see [0003](0003-on-device-speech-writing-assessment-for-mvp.md) and [ROADMAP.md](../ROADMAP.md).
- Requires careful Firestore Security Rules design (not yet written) to enforce the per-learner data isolation described in [SECURITY.md](../SECURITY.md) and [API_CONTRACT.md](../API_CONTRACT.md), since there's no server-side code to enforce it instead.
