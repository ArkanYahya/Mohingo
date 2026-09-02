# 0004: Local-only v1 — zero Firebase, no accounts, content shipped as a bundled asset

**Status:** Accepted

## Context

[ADR 0001](0001-offline-first-firebase-only-backend.md) committed to Firebase (Auth, Firestore, Cloud Storage) as the app's only backend, used from day one: Firebase Auth for sign-in, Firestore for cross-device progress sync, and Firestore/Cloud Storage as the distribution mechanism for published lesson content (the app downloads content from Firestore on launch, per the original [ARCHITECTURE.md](../ARCHITECTURE.md)).

A new, much more detailed build specification for the app (provided this session, alongside the actual A1 curriculum content package) explicitly requires the opposite starting point for v1: "the application must compile without a backend," no Firebase, no authentication, no cloud APIs "unless explicitly approved," and the curriculum content is to be copied into the Flutter project as a bundled asset (`assets/content/en/A1/a1-course-bundle.json`), not downloaded from a server. This was raised to the product owner as an explicit Decision Gate question this session ("Should v1 include any Firebase at all, or be fully local with zero backend?"), given it directly contradicts ADR 0001 as written. The owner's answer: **fully local, zero Firebase in v1** (the recommended option).

This is a genuine, material architecture change — not a minor implementation detail — because it removes the concept of a `Learner` account entirely from v1 (no sign-up/sign-in flow, no Firebase Auth UID as identity), removes the Firestore-download step from the content flow, and means every repository in the app has no remote counterpart actually wired up, only an interface shaped to accept one later.

## Decision

For v1, Mohingo ships with **no backend of any kind**: no Firebase Auth, no Firestore, no Cloud Storage, no accounts, no sign-in, and no network call required for any learning feature. The learner is identified by a locally-generated stable UUID, not a Firebase Auth UID. Curriculum content ships as a bundled Flutter asset, copied from the curriculum-authoring package's build output (`docs/a1-modular-course/dist/a1-course-bundle.json`) rather than downloaded from Firestore/Cloud Storage. All progress is stored exclusively in the local Drift database.

Every progress-relevant repository interface is still designed as if a remote counterpart existed (each record carries an app-level `uuid`, `updatedAt`, and a `deletedAt` soft-delete marker — see [DATA_MODEL.md](../DATA_MODEL.md)), so that a future sync layer can be added as a new repository implementation plus a Riverpod provider-binding swap, without a domain-layer rewrite. This is the mechanism, not just an aspiration — it's what makes this ADR a *timeframe-scoped* supersession of ADR 0001 rather than a reversal of it.

## Alternatives considered

- **Keep Firebase from day one, as ADR 0001 originally specified** — rejected for v1. Would add an account/sign-up flow, a Firestore-based content-publishing step, and a live Firebase project to provision and secure (Security Rules, etc.) before any of that is actually required by the MVP's feature set, which per [PRODUCT.md](../PRODUCT.md) is single-device, solo-learner content delivery. Directly contradicts the new build specification's explicit "must compile without a backend" requirement for v1.
- **A hybrid: Firebase Auth only (for future-proofing identity), but Firestore-free content/progress** — considered and rejected as unnecessary complexity. A locally-generated UUID already satisfies "don't make local database IDs the only public identity" (see [DATA_MODEL.md](../DATA_MODEL.md)) without requiring a live Firebase project or network call during onboarding; Firebase Auth can be introduced later, together with the rest of the sync layer, when there's an actual account/sync feature to build around it.

## Consequences

- Makes v1 genuinely, fully offline-capable with no exceptions — no network permission or background network call is required for any learning feature (a stronger guarantee than ADR 0001's original "offline-first," which still assumed an online content-download step).
- Removes onboarding friction and privacy surface area: no email/password, no auth tokens, no PII beyond `nativeLanguage`/`targetLanguage` and learning-progress data (see [SECURITY.md](../SECURITY.md)).
- Content updates require a manual build-and-copy step (curriculum tool → `assets/`) rather than a live publish-and-download flow; acceptable for a single-level (A1-only) v1, revisited when A2+ content and/or over-the-air content updates become a priority (see [ROADMAP.md](../ROADMAP.md)).
- Forecloses, for v1, any feature that inherently needs a backend: cross-device progress resume, account-based backup, and cloud-based AI grading (already deferred by [ADR 0003](0003-on-device-speech-writing-assessment-for-mvp.md)) all remain unavailable until a future ADR reintroduces Firebase for the sync phase described in [ROADMAP.md](../ROADMAP.md).
- **This ADR supersedes [0001](0001-offline-first-firebase-only-backend.md) for the v1 timeframe only.** ADR 0001's longer-term philosophy — Firebase as the *only* backend whenever a backend is actually needed, rather than a hand-rolled server — still stands and is expected to apply once account-based sync is built post-v1. ADR 0001 is not deleted or rewritten (per [docs/adr/README.md](README.md)'s rule against editing past ADRs); it carries a forward pointer to this ADR instead.
