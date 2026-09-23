# 0010: Optional accounts and cross-device progress sync (Firebase Auth + Firestore)

**Status:** Accepted — supersedes [0004](0004-local-only-v1-no-firebase-backend.md) in part (accounts and progress sync); 0004's bundled-content decision stands

## Context

[ADR 0004](0004-local-only-v1-no-firebase-backend.md) shipped v1 with no backend, no accounts, and progress in the local Drift database only. Changing phones, or reinstalling, started a learner from zero. The product owner asked (2026-09-23) for learners to sign in and keep their progress across devices, with four explicit decisions:

1. Reverse 0004's "no Firebase" for accounts and progress — yes.
2. Sign-in is **optional**: the app keeps working without an account, and progress made as a guest can be attached to an account later.
3. Offer **email/password and Google** sign-in now.
4. "Reset progress" while signed in resets **every device** on the account, after the learner confirms.
5. Android first; iOS later.

Constraints that shaped the design: the app must stay fully usable offline (CLAUDE.md's first rule); the Drift database already holds every piece of progress, and every progress row already has a stable `uuid`; answers (`activity_attempts`) are insert-only and unit mastery is *computed* from them; there is no server beyond Firebase ([ADR 0001](0001-offline-first-firebase-only-backend.md)).

## Decision

**Firebase Authentication** (email/password, Google) and **Cloud Firestore**, with the local Drift database remaining the single source of truth the app reads from.

1. **Local-first.** Every screen still reads Drift. A sync engine (`lib/features/sync/`) moves changes between Drift and Firestore in the background; no learning feature waits on it. Firestore's own offline cache is switched off — Drift already is the offline store, and a second cache would hide whether an upload really reached the server.
2. **An outbox fed by SQLite triggers** (`sync_outbox`, schema v6). Every insert or update of a synced table enqueues `(table, rowId)`, so a write path added later is synced without anyone remembering to. An entry is deleted only after the cloud acknowledged the upload. Records downloaded from the account are applied in a transaction that also removes the outbox entries the apply itself triggered, so they don't go back up.
3. **Firestore layout: one document per record, never one big document** — `users/{uid}` (epoch, name) and `users/{uid}/{attempts|testAttempts|lessonProgress|vocabularyReview|grammarReview|enrolments|dailyTasks}/{naturalKey}`. The document id is the record's natural key (its uuid, or its curriculum id), so a retried write lands on the same document. Each document carries `serverUpdatedAt` (a server timestamp), and a download asks only for documents written after the last one seen (a per-collection cursor, rewound one minute for safety). Static course content is never uploaded. `unit_progress` isn't synced at all: it is recomputed from the synced answers.
4. **Conflict rules, per collection** (`sync_merge.dart`, deterministic and order-independent — an exact tie is broken by a canonical encoding, so two devices always agree):
   - *Answers and daily-task events* never change once written: the two devices' sets are combined. Nothing either device recorded can be lost.
   - *Test attempts:* a finished attempt beats an unfinished copy; otherwise the later finish.
   - *Lesson position:* the later `updatedAt` wins.
   - *Vocabulary review:* the review schedule comes from the copy reviewed last (`lastReviewedAt`), the favourite from the copy that toggled it last (`favoriteUpdatedAt`, new in v6) — so a favourite set on one phone survives a later review on another.
   - *Grammar review:* the latest favourite toggle; the latest "reviewed" mark.
   - *Level enrolment:* the earliest start (with its course and content version), the latest selection, the earliest unlock.
   Uploads of mergeable records are merged with the server's copy **inside a Firestore transaction**, so two devices uploading at once both keep their changes; "last upload replaces everything" never happens.
5. **Account ownership on the device.** `learners` gains `firebase_uid` (unique). A device holds at most one guest learner plus one learner per account that has signed in on it; exactly one is active and every screen reads it (`AccountSessionController`). Signing out returns to the guest; the account's learner stays on the device, hidden, with any not-yet-uploaded changes, until *that* account signs in again. User B never sees user A's progress. The sync engine refuses to sync a learner whose `firebase_uid` isn't the signed-in account.
6. **Migrating existing progress.** The v6 upgrade queues every existing progress row, owned by the guest. On an account's first sign-in on a device: an empty guest simply becomes the account's learner; a guest *with* progress prompts "Add this phone's progress to your account?" — **Add** hands the guest learner to the account (its queued rows upload and are merged, by the rules above, with whatever the account already holds); **Keep it on this phone** starts the account from its own progress and leaves the guest's intact for after sign-out. Nothing syncs until the learner chooses, and neither choice deletes anything.
7. **Reset everywhere, via epochs.** `users/{uid}.epoch` is the account's progress generation. A confirmed reset erases local progress and marks the reset pending (one transaction); the next sync raises the epoch, then deletes the old records. Every other device sees a higher epoch on its next sync and erases its local progress for that account — including changes it hadn't uploaded yet, which were made before the reset reached it (the deterministic rule: a reset erases everything recorded against the old epoch). Records of an older epoch are ignored on download and refused by the store's merge; the epoch can only increase (Security Rules).
8. **Security Rules** (`firestore.rules`): only the signed-in owner can read or write `users/{uid}/**`; every document is validated against the exact shape the app writes (allowed keys, types, sizes, `serverUpdatedAt == request.time`); answers and daily-task events can only be rewritten unchanged; everything outside `users/` is denied. Tested against the emulator (`tool/firestore_rules_test/`).
9. **Firebase stays at the edges.** Only `FirebaseAuthRepository` and `FirestoreProgressStore` import Firebase; the rest of the app sees `AuthRepository`/`AuthUser`/`AuthFailure` and `CloudProgressStore`/`SyncRecord`. A build without Firebase configuration (`lib/firebase_options.dart` still the placeholder) runs exactly as before: local-only, no sign-in offered.

## Alternatives considered

- **Firestore's offline persistence as the local store** (drop Drift for progress) — rejected. Drift already holds and queries all progress (mastery aggregation is SQL); moving it would rewrite every repository, and Firestore's cache can't answer those queries offline.
- **One document per learner, rewritten on each sync** — rejected: the owner explicitly ruled it out, it hits Firestore's 1 MB limit with a year of answers, and it makes "last writer replaces everything" the conflict rule.
- **Repository write paths enqueue explicitly** instead of triggers — rejected: ~25 write methods across 7 repositories, and every future write path would have to remember. Triggers make it structural.
- **Per-field timestamps on every table** — rejected as more than the data needs. Only the vocabulary/grammar favourite genuinely changes independently of the rest of its row, so only it got its own timestamp.
- **Deleting cloud documents to reset** (no epochs) — rejected: an offline device would re-upload the deleted progress when it reconnected.
- **Forcing sign-in** — rejected by the owner; the app's offline, no-friction start stays.
- **Silently attaching guest progress on sign-in** — rejected: the phone might have been used by someone else. The learner decides.

## Consequences

- Progress now survives reinstalls and moves between phones, for learners who sign in. Guests are exactly where they were in v1.
- A Firebase project exists and must be configured (`docs/FIREBASE_SETUP.md`); `lib/firebase_options.dart` and `android/app/google-services.json` are committed (they identify the project; they are not secrets — see [SECURITY.md](../SECURITY.md)).
- Network is used for sign-in and sync only; still no learning feature requires it (CLAUDE.md's rule holds). [ADR 0005](0005-narrow-network-exception-for-open-ended-grading.md)'s refinement exception is unchanged.
- Clock skew between devices can mis-order two edits of the *same* lesson position or word made within the skew; answers are never affected. Accepted.
- A reset on one device discards another device's not-yet-uploaded work made before it learned of the reset. Documented, deterministic, and what "reset everywhere" means.
- **Store obligations this creates** (not yet built — see [ROADMAP.md](../ROADMAP.md)): Google Play requires in-app **account deletion** for apps that let users create accounts; the App Store requires **Sign in with Apple** once Google sign-in is offered on iOS.
- iOS needs its own Firebase app registration, `GoogleService-Info.plist`, and the Google URL scheme before sign-in works there.
