> **What this file is:** The auth model, how secrets are handled, and the hard limits nothing should cross (e.g. "never log PII"). Security rules are exactly the kind of thing that must never be re-derived per session — they must be inherited.
> **How to use it:** Treat every rule here as a hard constraint, not a guideline. If a task seems to require violating one, stop and raise it rather than making a local exception.

_Last verified: 2026-09-01 — initial security model established via brainstorming session._

# Security

## Auth model

- Mechanism: Firebase Auth (email/password at minimum; Sign in with Apple required if any other third-party sign-in is offered, per App Store rules — finalize exact providers when auth is implemented).
- Roles/permissions: single role — `Learner`. No in-app admin/author role; content authoring happens entirely outside the app via the separate dev-time tool using Firebase admin credentials (see [ARCHITECTURE.md](ARCHITECTURE.md)).
- Token lifetime/refresh: handled automatically by the Firebase Auth SDK — no custom token logic.

## Secrets handling

- Where secrets live: LLM API keys used for content generation live only in the separate dev-time authoring tool's local environment (e.g. `.env`, gitignored) — never bundled into the shipped app, never committed.
- Firebase client config (`google-services.json` / `GoogleService-Info.plist`) is bundled into the app per standard Firebase practice — this is not a secret by Firebase's own model, but access to Firestore/Storage data is enforced by Security Rules, not by hiding this config.
- Rule: never commit secrets, never ship secrets to the client (standing rule).

## Data handling

- PII fields: auth email, `Learner.nativeLanguage`/`targetLanguage` (personal but not sensitive), Attempt history (learning progress).
- What must never be logged: auth email, auth tokens. Speaking exercises are transcribed on-device only (see [TECH_STACK.md](TECH_STACK.md)) — raw audio is never uploaded, stored remotely, or logged.
- Encryption at rest / in transit: Firestore/Cloud Storage use Firebase's default encryption at rest and TLS in transit. The local Drift database is not encrypted by default for MVP — acceptable given the limited PII involved (no payment data, no writing-sample content sensitive beyond normal learning data); revisit if that changes.

## Hard limits

- No client-side secret keys — the LLM API key is never bundled into the shipped app.
- Firestore/Storage Security Rules must enforce that a Learner can only read/write their own `/learners/{learnerId}` and `/learners/{learnerId}/attempts/*` documents (see [API_CONTRACT.md](API_CONTRACT.md)); all other content collections are client-read-only.
- All external input (exercise answers, placement-test responses) validated before being written to Drift/Firestore — never trust client-submitted data as pre-validated when it affects progress-gating.

## Dependency / vulnerability policy

Solo project — lightweight policy: periodically run `flutter pub outdated`, review changelogs before upgrading Firebase SDKs specifically (they touch auth and data access), and prioritize security patches over feature-driven upgrades.
