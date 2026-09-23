> **What this file is:** The source of truth for what the API looks like from the outside — endpoints, request/response shapes, status codes. Prevents the frontend and backend (or different sessions working on either) from silently diverging.
> **How to use it:** Update *before or alongside* changing an endpoint, not after. If the project adopts a formal schema (OpenAPI/GraphQL SDL), that generated/authored file becomes the real source of truth — keep this doc as a human-readable index pointing to it.

_Last verified: 2026-09-23 (`claude/firebase-auth-sync-ji1cww`) — now the Firestore contract of progress sync ([ADR 0010](adr/0010-optional-accounts-and-progress-sync.md)). Previously (2026-09-02) a placeholder: v1 had no backend ([ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md))._

# API Contract

There is no custom server ([ADR 0001](adr/0001-offline-first-firebase-only-backend.md)). The app talks to **Firebase Authentication** (sign-in) and **Cloud Firestore** (a signed-in learner's progress). Curriculum content is not part of this contract: it ships inside the app and is never uploaded.

The schema below is enforced in three places, which must change together: `SyncCollection.fields` (`lib/features/sync/domain/sync_records.dart` — what the app writes and accepts), `firestore.rules` (what the server accepts), and `tool/firestore_rules_test/rules.test.js`.

## Authentication

Firebase Auth, providers **Email/Password** and **Google**. The account id is the Firebase UID. Nothing else about the user is stored in Firestore — no email, no display name from Google.

## Documents

All paths are under `users/{uid}`, where `uid` is the signed-in account's UID. Times are Firestore timestamps (UTC).

### `users/{uid}` — the account

| Field | Type | Notes |
|---|---|---|
| `epoch` | int ≥ 0 | Progress generation. Raised by "Reset progress"; only ever increases. |
| `name` | string ≤ 100 \| null | The learner's display name (Settings). |
| `nameUpdatedAt` | timestamp \| null | Last-writer-wins clock for `name`. |
| `createdAt` | timestamp | Server time of creation; never changes. |
| `serverUpdatedAt` | timestamp | Server time of the last write. |
| `v` | int = 1 | Schema version. |

### Every progress record, `users/{uid}/{collection}/{docId}`

Besides its own fields, every record carries `epoch` (the account epoch it was written under — records of an older epoch are erased progress, ignored on download and deleted after a reset), `serverUpdatedAt` (server time of the write; the download cursor) and `v` (= 1).

| Collection | `docId` | Fields | Changes after first write? |
|---|---|---|---|
| `attempts` | answer uuid | `uuid`, `activityId`, `lessonId?`, `sessionType`, `sessionId?`, `mode`, `evidenceSkill`, `rawAnswer?`, `isCorrect?`, `score?`, `criteriaScores?`, `wasFallback`, `attemptedAt`, `updatedAt`, `canDoIds` (list) | Never (rewrite unchanged only) |
| `dailyTasks` | event uuid | `uuid`, `taskType`, `occurredAt` | Never |
| `testAttempts` | attempt uuid | `uuid`, `kind` (`placement`\|`finalMission`\|`finalAssessment`), `courseId?`, `startedAt`, `completedAt?`, `stageReached?`, `outcome?`, `recommendedUnitId?`, `confidenceSelfReports?`, `itemSamplingSeed?`, `stagesCompleted?`, `sectionResults?`, `outcomeSummary?` | Merged: a finished copy wins |
| `lessonProgress` | lesson id | `lessonId`, `unitId`, `state`, `lastActivityId?`, `lastPositionUpdatedAt?`, `updatedAt` | Merged: later `updatedAt` |
| `vocabularyReview` | `lexicon:<id>` or `chunk:<id>` | `lexiconId?`, `chunkId?`, `isFavorite`, `favoriteUpdatedAt?`, `confidenceMarker?`, `easeFactor`, `intervalDays`, `repetitions`, `dueAt?`, `lastReviewedAt?`, `updatedAt` | Merged: schedule by `lastReviewedAt`, favourite by `favoriteUpdatedAt` |
| `grammarReview` | grammar id | `grammarId`, `isFavorite`, `favoriteUpdatedAt?`, `markedReviewedAt?`, `updatedAt` | Merged: favourite by `favoriteUpdatedAt`, latest `markedReviewedAt` |
| `enrolments` | level id (`a1`, `a2`) | `levelId`, `courseId`, `contentVersion`, `enrolledAt`, `status`, `lastSelectedAt?`, `unlockedAt?` | Merged: earliest start, latest selection, earliest unlock |

Document ids are URI-encoded (`Uri.encodeComponent`). `?` marks a field that may be null. JSON-valued fields (`rawAnswer`, `sectionResults`, …) are strings, stored exactly as the local database holds them.

## Operations the app performs

- **Upload** — append-only records by batched `set`; mergeable records inside a transaction that reads the stored copy, merges ([ADR 0010](adr/0010-optional-accounts-and-progress-sync.md) decision 4) and writes the result. A stored copy under a *newer* epoch aborts the upload (another device reset progress).
- **Download** — per collection: `orderBy(serverUpdatedAt).orderBy(__name__)`, after the saved cursor, 300 per page. Served by Firestore's automatic single-field index; no composite index is required.
- **Reset** — transaction on `users/{uid}` raising `epoch`; then delete records `where epoch < newEpoch`.

## Security Rules (summary of `firestore.rules`)

- Only `request.auth.uid == uid` may read or write `users/{uid}` and anything under it. No listing of `users`. Everything outside `users/` is denied.
- Every write must match the table above exactly: allowed keys only, types, string lengths, `serverUpdatedAt == request.time`, `v == 1`, and for uuid-keyed records `docId == uuid`.
- `attempts` and `dailyTasks` can be rewritten only unchanged (a retried upload).
- `users/{uid}.epoch` can't decrease; `createdAt` can't change.
