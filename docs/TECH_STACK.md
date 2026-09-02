> **What this file is:** The chosen technologies and the reasoning behind each choice — not just *what* we use but *why*, and what we deliberately didn't pick.
> **How to use it:** Check before adding a new library/framework/service. If something isn't listed, it isn't approved yet — raise it for discussion rather than adding silently. A stack change belongs here *and* as an entry in [adr/](adr/).

_Last verified: 2026-09-02 — v1 rescoped to fully local/zero-Firebase (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)); added go_router, content-model, speech, and utility packages driven by the real A1 curriculum bundle inspected this session._

# Tech Stack

## Frontend

- **Framework:** Flutter (Dart), current stable channel — why: single codebase for iOS + Android, strong built-in RTL support (needed for Arabic UI), good offline-first story.
- **State management / DI:** Riverpod (`flutter_riverpod` + `riverpod_annotation`/`riverpod_generator`) — standard, testable state management for Flutter; codegen keeps the many repository/service providers this app needs (content, progress, speech) low-boilerplate.
- **Navigation:** `go_router` — official Flutter routing package. `StatefulShellRoute.indexedStack` is the right primitive for the 5-tab bottom nav (Home/Learn/Review/Tests/Settings) with independent per-tab navigation stacks, plus typed/centralised routes and a root `redirect` that gates all routes on curriculum-content-load status (loading/unsupported/ready) — see [ARCHITECTURE.md](ARCHITECTURE.md).
- **Alternatives considered:** React Native/Expo — would let logic share with a JS/TS backend, but the app has no custom backend (see below), so that advantage doesn't apply here; Flutter's RTL support tipped the decision.

## Backend

- **v1: none at all.** The app compiles and runs with zero backend, zero accounts, zero required network calls for any learning feature — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). This is a stronger statement than "offline-first" alone: v1 has no Firebase SDK usage whatsoever, not even for auth.
- **Deferred, post-v1:** Firebase (Auth, Firestore, Cloud Storage) as a Backend-as-a-Service, for account-based progress sync and eventual multi-level content distribution — the longer-term direction [ADR 0001](adr/0001-offline-first-firebase-only-backend.md) originally described, now scoped to *after* v1 rather than from day one. Repository interfaces are written now (see [ARCHITECTURE.md](ARCHITECTURE.md)) so this can be added as a new implementation + provider-binding swap, not a domain-layer rewrite.
- **Alternatives considered:** Python/FastAPI, Node.js/TypeScript — rejected; a maintained server isn't needed for a solo, offline-first app, and adds operational burden with no corresponding benefit at this stage.

## Database

- **Local (on-device):** Drift (SQLite-based) — stores learner progress only (enrolments, attempts, mastery evidence, review state — see [DATA_MODEL.md](DATA_MODEL.md)). It does **not** store curriculum content: the A1 bundle is a bundled read-only asset, parsed and indexed in memory (see [ARCHITECTURE.md](ARCHITECTURE.md)'s `lib/content/` module), and Drift only ever references the bundle's stable string IDs. Explicit schema migrations from day one even though v1 ships only one schema version.
- **Cloud (sync):** none in v1 — deferred alongside the backend decision above. When added, Firestore remains the planned choice for cross-device progress sync.
- **Device/UI preferences:** `shared_preferences` for small, non-critical settings only (theme mode, colour theme, interface language, text scale, TTS voice/rate/pitch, "seen onboarding" flag) — never for progress data, so a "reset progress" action in Settings can never accidentally also reset the learner's language/theme.
- **Alternatives considered:** Isar, Hive — considered for local storage; Drift chosen for its relational/SQL querying, which fits structured curriculum-reference and mastery-evidence data (e.g. one indexed join per Can-Do objective across skill groups) better than a pure key-value/NoSQL local store.

## Content models

- **Immutable content models:** `freezed` + `json_serializable` (+ `build_runner`), scoped specifically to `lib/content/models/` — the curriculum bundle's nested, sealed-union shapes (9 activity types, 8 media-specification types) benefit from freezed's union support and reliable `fromJson`/`toJson`. **Not** used for Drift row classes, which already generate their own immutable data classes — avoiding redundant/colliding codegen.
- **Why not hand-written models throughout:** the bundle graph is large (~1,200 leaf records across units/lessons/activities/grammar/lexicon/chunks/media) and schema-versioned; generated `fromJson` plus a `schemaVersion` guard is more reliable than hand-rolled parsing for something this size.

## Localisation

- **Flutter's ARB-based l10n** (`flutter_localizations` + generated `AppLocalizations`) — app-chrome strings only (buttons, navigation, system messages). Curriculum content (lesson text, grammar/vocabulary explanations) is bilingual *within the bundle itself* (`en`/`ar` fields per record), never routed through ARB files.

## Speech

- **On-device TTS:** `flutter_tts` — wraps iOS `AVSpeechSynthesizer` / Android `TextToSpeech`; exposes voice/rate/pitch/locale selection where the OS does. Reads the curriculum bundle's `audioTranscript`/`ttsSource` records at runtime — the bundle ships no pre-recorded audio files at all.
- **On-device STT:** `speech_to_text` (already decided, [ADR 0003](adr/0003-on-device-speech-writing-assessment-for-mvp.md)) — exposes per-locale on-device availability, a listen/result stream, offline-vs-online status.
- **Microphone permission:** `permission_handler` — unifies iOS Info.plist-driven and Android runtime-permission flows behind one call; needed to check/request mic permission only when a speaking task is deliberately started, and to report status plainly in Settings.

## Utilities

- **`uuid`** — generates the app-level stable identity (`Learner.id` and every syncable progress record's `uuid` column) that a future sync layer will key on; deliberately not a Firebase Auth UID in v1 (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)).
- **`path_provider`** — resolves the app documents directory for the local SQLite file.
- **`collection`** (Dart team) — grouping/indexing utilities used building the in-memory `CourseContentIndex`.

## Infrastructure / hosting

- **v1:** none — no servers, no Firebase project required to run the app.
- **Deferred, post-v1:** Firebase (Auth, Firestore, Cloud Storage) once account sync is built — see Backend section above.
- **CI/CD:** TBD — to be decided when the build/release process is set up (likely Codemagic or GitHub Actions for Flutter builds).

## Third-party services

| Service | Purpose | Notes |
|---|---|---|
| Platform text-to-speech (`flutter_tts`) | Reads curriculum `audioTranscript`/`ttsSource` text aloud at runtime; also used for Vocabulary/Grammar pronunciation playback | Offline, no API cost, no pre-recorded audio assets needed |
| Platform speech-to-text (`speech_to_text` package, wrapping iOS/Android native engines) | On-device speaking task-completion checks | Offline, no API cost; never presented as pronunciation/fluency/CEFR scoring — see [ADR 0003](adr/0003-on-device-speech-writing-assessment-for-mvp.md) |
| LLM API (e.g. Claude) | Content generation — used in the offline dev-time authoring pipeline only (`docs/a1-modular-course/`), not called by the shipped app | You review/edit AI output before it's built into the runtime bundle; never bundled as a client-side key — see [SECURITY.md](SECURITY.md) |

**Deferred to post-v1** (not used by the shipped app in v1): Firebase Auth, Firestore, Firebase Cloud Storage — see Backend section above and [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md).

**Explicitly not adopted for v1:** any analytics or crash-reporting SDK, any local-backup export/import mechanism — both decided out of scope this session; see [ROADMAP.md](ROADMAP.md).

## Explicitly rejected

| Option | Reason rejected |
|---|---|
| Custom backend server (Python/FastAPI or Node.js) | Not needed for a solo, offline-first app; if/when a backend is added post-v1, Firebase covers the actual requirements (auth, sync, storage) without server upkeep. |
| Cloud-based AI grading for speaking/writing at runtime | Conflicts with "fully offline" requirement for MVP; deferred to post-MVP roadmap (see [ROADMAP.md](ROADMAP.md)) once a serverless AI-grading path (e.g. Firebase Cloud Functions) is worth the added complexity. |
| React Native/Expo | Flutter's RTL support and single-codebase story fit better; no backend exists to share TypeScript types with. |
| Bundling artwork/SVG assets for the curriculum's 7 structured scene-media types (`peopleCard`, `personCard`, `peopleMap`, `homePlan`, `objectScene`, `distanceScene`, `apartmentPlan`) | These are structured scene *descriptions* in the bundle, not image files — no artwork exists to bundle. Rendered instead as small in-app diagrams built from the data (see [ARCHITECTURE.md](ARCHITECTURE.md)); `flutter_svg` and similar packages are therefore not needed. |
| Analytics / crash-reporting SDK in v1 | Decided out of scope this session — keeps zero required network calls/third-party telemetry while the app is fully local; see [ROADMAP.md](ROADMAP.md). |
