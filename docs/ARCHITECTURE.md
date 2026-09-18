> **What this file is:** The high-level shape of the system — layers, boundaries, data flow, folder structure. The single biggest lever for keeping AI sessions from drifting, since most inconsistency comes from this not being written down.
> **How to use it:** Read before adding a new module or changing how data flows. If a change alters this shape, update the diagram/description *and* record the reasoning as an [ADR](adr/).

_Last verified: 2026-09-18 — corrected how words enter spaced review (rating on their page, not lessons); word and phrase pages share `VocabularyDetailView`, and a word's review status is `vocabularyStatus`. Earlier the same day: the Review tab gained a review session (`/review/session`, a full-screen route beside `/review/practice`) and `review/domain/` (`weakSpotsFor`, `daysUntilNextReview`). Earlier the same day: the Learn tab opens on the A1 course (`CourseScreen`), the `course_catalog` feature folder is gone, units moved to `/learn/unit/<id>` with redirects from the old addresses. Earlier the same day: the speech service's `speak()` now completes when the utterance finishes (with a timeout), which the lesson player's conversation relies on. Previously verified 2026-09-08 — rescoped for the local-only, zero-Firebase v1 decided this session (see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)); added the `lib/content/` module and the curriculum-bundle content-loading flow, grounded in the actual A1 bundle at `docs/a1-modular-course/dist/a1-course-bundle.json`. Phase 9 implemented `placement_test`/`final_mission`/`final_assessment` (previously listed as planned feature areas only) — see the note at the end of "Key flows" below. 2026-09-08: `lib/content/`'s "never imports from `lib/features/`" rule written down explicitly, after the offline-answer-evaluation work briefly inverted it; `EvaluationSpec` (pure bundle data) now lives in `lib/content/models/evaluation_spec.dart`, while grading it stays in `lib/features/activity_engine/domain/evaluation/`._

# Architecture

## Overview

Mohingo v1 is a fully local, offline Flutter mobile client (iOS + Android) with **no backend at all** — not even for auth. A separate, non-shipped dev-time tool (`docs/a1-modular-course/`) handles AI-assisted content authoring: an LLM drafts lesson content, the author reviews/edits it, and the curriculum package's own build tooling produces one runtime bundle (`dist/a1-course-bundle.json`) that is copied into the Flutter app as a bundled asset — not downloaded from anywhere. Firebase (Auth, Firestore, Cloud Storage) as a Backend-as-a-Service, and account-based cross-device progress sync, are both deferred to a later phase — see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md), which supersedes [ADR 0001](adr/0001-offline-first-firebase-only-backend.md) for the v1 timeframe.

## Layers / boundaries

```
UI (widgets)
  -> state (Riverpod providers/notifiers)
    -> repository layer
      -> local data (Drift/SQLite) — progress only, the source of truth for what the app renders
      -> remote data (Firestore / Cloud Storage) — NOT IMPLEMENTED in v1; interfaces exist as a
         future-sync seam only (see "Repositories and future sync" below), no class calls out to it
```

A separate, third data source sits alongside the two above: **bundled curriculum content** (`lib/content/`), loaded once from a Flutter asset and held in memory — never mirrored into Drift. See "Content module" below.

A separate on-device **speech service** (native TTS/STT) is called directly from lesson-player/vocabulary/grammar features via its own DI-bound interface — it doesn't go through the repository/data layers since it's a device capability, not persisted content. `TextToSpeechService.speak()` completes when the utterance *finishes* (or fails, or is stopped), not when it starts — the device implementation turns on `flutter_tts`'s `awaitSpeakCompletion` and caps each utterance with a length-based timeout so an engine that never reports can't hang a caller. The lesson player's conversation relies on this to read lines in sequence.

Rules for crossing layers:
- UI never talks to Drift, the content asset, or (later) Firestore directly — always through a repository or the content-index provider. This keeps local-vs-remote swappable and the UI testable against a fake repository.
- The local database (Drift) is the source of truth for *progress*; the parsed content bundle is the source of truth for *curriculum content*; the two are never merged into one store, and Drift only ever references the bundle's stable string IDs (never duplicates bundle content).

## Folder structure

```
lib/
  core/            # theme (ColorScheme/ThemeExtension), router (go_router), l10n wiring,
                    #   media (diagram renderers for the curriculum's structured scene types),
                    #   shared widgets (loading/empty/error/unsupported-content states), utils
  content/         # bundled curriculum ONLY — read-only, never mutated, never imported by data/local,
                    #   and never importing from lib/features/ (it is a foundational layer *under*
                    #   the feature layer; anything a feature needs from it flows one way only)
    models/          # typed immutable models (freezed) for the bundle's shape: units, lessons,
                      #   activities (9 types), an activity's structured `evaluation` grading spec
                      #   (EvaluationSpec — pure data; *evaluating* it is a feature concern and
                      #   lives in features/activity_engine/domain/evaluation/),
                      #   grammar/lexicon/chunk registries, media specs,
                      #   final mission, final assessment, domain definitions (skills/modes/canDo/policy)
    parsing/         # CourseBundleParser + schemaVersion/contentVersion validation
    index/           # CourseContentIndex — id -> object maps, built once at startup
    catalog/         # app-owned level-availability table (A1 = available, A2-C2 = comingSoon)
    providers/       # Riverpod providers exposing the loaded bundle + index, kept alive app-lifetime
  data/
    local/           # Drift schema (progress tables only), DAOs, migrations
    remote/          # EMPTY in v1 — future-sync seam only, no implementation registered
  features/
    <feature>/
      presentation/  # widgets, screens
      application/   # Riverpod providers/notifiers
      domain/        # entities, business rules
      data/          # feature-specific repository implementations (local-backed in v1)
```

Feature areas: `app_shell, onboarding, learning_path, lesson_player, activity_engine, vocabulary, grammar, review, placement_test, final_mission, final_assessment, progress, speech, settings`. Which levels exist and are available is the app-owned catalogue in `lib/content/catalog/level_catalog.dart` (`kLevelCatalog`), kept distinct from `learning_path` (the A1 course page and unit pages) — this split is what makes adding an A2 bundle later purely additive, with zero changes to A1 code. The Learn tab (`/learn`) opens straight on the A1 course (`CourseScreen`); units are at `/learn/unit/<id>`. There is no separate level-list screen any more — unavailable levels are a "Coming later" strip on the course page — and the old addresses `/learn/<level>` and `/learn/<level>/unit/<id>` redirect (`legacyLearnRedirect`). A future second level would bring back a level switcher on the course page, not a separate screen.

## Repositories and future sync

Every progress-relevant repository interface (e.g. `MasteryEvidenceRepository`) is written today as if a remote counterpart already existed: progress records carry an app-level `uuid`, `updatedAt`, and `deletedAt` (soft-delete marker) even though v1 never reads them. Only one implementation exists in v1 (`Drift...Repository`), bound via Riverpod. Adding sync later means writing a *new* implementation and swapping the provider binding — no caller, and no domain-layer code, needs to change.

## Key flows

**Content (author → learner, v1):** dev-time curriculum pipeline runs in `docs/a1-modular-course/` → LLM drafts lesson content → author reviews/edits → curriculum's own validators/build tool (`validate-a1.mjs`, `audit-quality.mjs`, `build-a1.mjs`) produce `dist/a1-course-bundle.json` → that file is copied verbatim into the Flutter project as an asset (`assets/content/en/A1/a1-course-bundle.json`) → at app startup, parsed once off the UI isolate, `schemaVersion` validated, indexed into `CourseContentIndex` → lessons render from that in-memory index. No network call is involved anywhere in this flow after the app is installed. (Deferred, post-v1: replacing the "copied at build time" step with a Firestore-hosted download-on-launch step, per [ADR 0001](adr/0001-offline-first-firebase-only-backend.md)'s original longer-term direction.)

**Vocabulary review (learner, v1):** a word or phrase enters the spaced-review queue (`vocabulary_review_state`) the first time the learner rates it on its word/phrase page (`VocabularyDetailView`) — lessons don't add items; the Review tab's Start review opens `ReviewSessionScreen`, which snapshots everything due when it opens and saves each Again/Good/Easy rating through `VocabularyReviewService` (the same simplified SM-2 `SpacedReviewScheduler` the word pages use) as it goes, so closing early keeps what was rated. This is memory scheduling only — it never writes mastery evidence. Weak Can-Do goals (`weakObjectivesProvider`) are shown through `weakSpotsFor`, which groups them by the first non-mission lesson that teaches them, since the bundle has no learner-facing Can-Do text.

**Progress (learner, v1):** learner completes an activity → written to local Drift immediately, insert-only (a replay appends a new attempt row rather than overwriting, so mastery history survives revisits) → a `MasteryAggregationService` recomputes cached per-unit/per-objective state from the evidence rows. No sync step exists in v1 — progress never leaves the device. (Deferred, post-v1: a background push to Firestore when a connection is available, enabling cross-device resume, once accounts exist.)

**Placement / Final Mission / Final Assessment (Phase 9):** the bundle has no dedicated placement-item pool at all (verified against the real data), so `PlacementItemSampler` draws receptive (listening/reading) items from each unit's own `practice`-mode activities, and its one productive (write/speak) supporting item from either `practice`- or `mastery`-mode content — real-content check showed every unit except `A1-U0` has zero `practice`-mode write/speak activities, so restricting to `practice` there would silently skip that step almost everywhere. What actually keeps a placement item out of real training/mastery evidence is the `sessionType='placement'` it's recorded under (`ActivityAttemptRepository.masteryEvidenceForObjective` filters to `sessionType='lesson'` only), never the source activity's own `mode`. `PlacementClassifier` scans units in curriculum order and stops at the **first** unit that fails (>= 2 items sampled, < 60% correct) — that stopping point is itself the recommendation, so this collapses the originally-proposed "fixed foundation stage + adaptive receptive stage" into one continuous adaptive pass rather than two. A single confidence self-report is collected afterward as supporting info only, never affecting the outcome. `PlacementTestScreen`'s item-sampling RNG seed is exposed via an overridable `placementSeedProvider` (the same pattern used for `TextToSpeechService`/`SpeechCapabilityService`), making the whole flow deterministically testable end-to-end despite depending on real random sampling in production — see `test/features/placement_test/placement_test_screen_test.dart`. Final Mission and Final Assessment need no sampling (they read the bundle's own dedicated `finalMission`/`finalAssessment` objects directly); both are scored per skill/skill-group independently (`FinalMissionScoring`/`FinalAssessmentScoring`), never one blended average, and any item this app can't auto-grade (free-response writing/speaking with no `accepted` answer key) is reported `pendingReview` rather than guessed at — this app has no rubric evaluator yet, see [TECH_STACK.md](TECH_STACK.md).

## Cross-cutting concerns

- **Auth:** none in v1 — no accounts, no sign-in. A single local `Learner` profile is created on first launch, identified by a locally-generated stable UUID (not a Firebase Auth UID). See [SECURITY.md](SECURITY.md) and [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Deferred, post-v1: Firebase Auth, once account sync is built.
- **Error handling:** typed exceptions thrown from the repository/content-parsing layers, caught and translated to user-facing messages at the UI layer — see [CONVENTIONS.md](CONVENTIONS.md). An unsupported/corrupted content bundle produces a typed `UnsupportedContentSchemaException`/`ParseError`, routed to a dedicated "unsupported content" screen, never a raw crash.
- **Logging / observability:** no analytics or crash-reporting SDK in v1 (decided this session — see [ROADMAP.md](ROADMAP.md)); answers, personal text, and speech transcripts are never logged in release builds regardless.
- **Config / secrets:** LLM API keys used for content generation live only in the separate dev-time authoring tool and are never bundled into the shipped app. No Firebase config is bundled in v1 (there is no Firebase SDK usage at all).

## Deployment topology

Mobile app distributed via the Apple App Store and Google Play. **No hosted infrastructure of any kind in v1** — no server, no Firebase project. The content-authoring tool runs locally on the author's machine, not deployed anywhere; its output is copied into the app repo as a versioned asset at build time. (Deferred, post-v1: a Firebase project, once account sync is built.)
