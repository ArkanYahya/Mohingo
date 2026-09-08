> **What this file is:** The auth model, how secrets are handled, and the hard limits nothing should cross (e.g. "never log PII"). Security rules are exactly the kind of thing that must never be re-derived per session — they must be inherited.
> **How to use it:** Treat every rule here as a hard constraint, not a guideline. If a task seems to require violating one, stop and raise it rather than making a local exception.

_Last verified: 2026-09-08 — added ADR 0005 and its narrow network exception for grammar-check on open-ended answers (see [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md)); updated the "no data leaves device" and "no network required" hard limits accordingly. The raw-audio and secrets-handling rules remain unchanged. Phase 8 confirmed the actual speech implementation matches this doc: mic permission is only requested from a deliberate "Enable microphone" tap, and a speech transcript exists only in local widget state before scoring, never persisted verbatim. Phase 10 found and fixed a real store-blocking gap: `android/app/src/main/AndroidManifest.xml` was missing `RECORD_AUDIO` entirely (speech_to_text's permission checks would always fail on a real Android device) and `ios/Runner/Info.plist` was missing `NSMicrophoneUsageDescription`/`NSSpeechRecognitionUsageDescription` (iOS terminates an app that requests a permission with no matching usage-description string — this would have crashed the very first speaking-task attempt on a real iPhone). Both are fixed; see [TECH_STACK.md](TECH_STACK.md)'s Speech section for the exact keys added and the still-open Arabic-localization gap for the iOS strings. Phase 10 also added Settings' "Reset progress" action (`AppDatabase.resetProgressForLearner`) — confirmed here to match this doc's PII scope: it deletes every progress/attempt/review row for the learner but never the `Learners` row's UUID itself, so it's a progress reset, not an identity reset._

# Security

## Auth model (v1)

- **No accounts, no sign-in, no Firebase Auth in v1.** A single local `Learner` profile is created automatically on first launch, identified by a locally-generated stable UUID (see [DATA_MODEL.md](DATA_MODEL.md)) — there is nothing to authenticate against, since there is no backend at all.
- Roles/permissions: single implicit role — `Learner`. No in-app admin/author role; content authoring happens entirely outside the app via the separate dev-time curriculum tool (`docs/a1-modular-course/`), which never runs on a learner's device (see [ARCHITECTURE.md](ARCHITECTURE.md)).
- **Deferred, post-v1:** Firebase Auth (email/password at minimum; Sign in with Apple required if any other third-party sign-in is offered, per App Store rules), once account-based sync is built — the original direction in [ADR 0001](adr/0001-offline-first-firebase-only-backend.md), now scoped to that later phase per [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md).

## Secrets handling

- Where secrets live: LLM API keys used for content generation live only in the separate dev-time authoring tool's local environment (e.g. `.env`, gitignored) — never bundled into the shipped app, never committed. Unchanged by the local-only decision — this rule was never about Firebase.
- **No Firebase client config is bundled in v1** — there is no Firebase SDK usage at all, so `google-services.json`/`GoogleService-Info.plist` don't apply until the deferred post-v1 sync phase.
- Rule: never commit secrets, never ship secrets to the client (standing rule).

## Data handling

- PII fields (v1): `Learner.nativeLanguage`/`targetLanguage` (personal but not sensitive), Attempt history (learning progress) — see [DATA_MODEL.md](DATA_MODEL.md). No auth email or auth tokens exist in v1, since there are no accounts.
- What must never be logged: any learner-entered answer text, any speech transcript, the local learner UUID. Speaking activities are transcribed on-device only (see [TECH_STACK.md](TECH_STACK.md)) — raw audio is never uploaded (there is no server to upload to in v1), never stored at rest, and never logged; only minimal derived scoring data (e.g. task-completion flags) is persisted, and a verbatim transcript shown to the learner pre-submit is discarded after scoring.
- Encryption at rest / in transit: no data leaves the device in v1, **with one narrow, bounded exception**: an open-ended writing/speaking answer (only the ~40 rubrics marked `onlineRefinement`), when the device is online, may be sent over HTTPS to the free public LanguageTool API for a grammar-quality check — never blocking, never required (a bounded local-only fallback resolves it either way), and disclosed to the learner before it first applies. See [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md). The local Drift database is not encrypted by default for v1 — acceptable given the limited PII involved (no payment data, no accounts); revisit if that changes.

## Hard limits

- No client-side secret keys — the LLM API key is never bundled into the shipped app.
- **No network permission or background network call is required for any learning feature in v1** — still true after [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md): online grammar refinement for open-ended answers is a bounded quality upgrade with a working offline fallback, never a requirement. Verify at build time that no plugin silently requires `INTERNET` beyond what ADR 0005 and platform tooling account for.
- Microphone permission is requested only when a learner deliberately starts a speaking task, never on activity mount or app launch — see [ARCHITECTURE.md](ARCHITECTURE.md)'s speech feature and [TECH_STACK.md](TECH_STACK.md).
- All external input (activity answers, placement-test responses) validated before being written to Drift — never trust client-submitted data as pre-validated when it affects mastery evidence.
- **Deferred, post-v1:** Firestore/Storage Security Rules enforcing per-learner data isolation, once accounts and sync exist (see [API_CONTRACT.md](API_CONTRACT.md), currently N/A for v1).

## Dependency / vulnerability policy

Solo project — lightweight policy: periodically run `flutter pub outdated`, review changelogs before upgrading — with particular attention to `drift`/`drift_flutter` (local data access), `speech_to_text`/`flutter_tts`/`permission_handler` (microphone access, a sensitive OS permission) — and prioritize security patches over feature-driven upgrades. Revisit this list to include Firebase SDKs once the deferred post-v1 sync phase adds them.
