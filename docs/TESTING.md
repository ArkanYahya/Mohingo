> **What this file is:** What must be tested, at what level, and how to run it. Keeps test coverage expectations consistent instead of depending on whichever session happens to be writing a feature.
> **How to use it:** Check before adding a feature — what test(s) does this convention require? Update the commands section the moment the test setup changes so it never goes stale.

_Last verified: 2026-09-09 — expanded coverage list for the real curriculum bundle, the mastery-evidence model, and the local-only v1 (sync testing deferred); see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Phase 9 implemented the "Placement/mission/assessment" row below in full: classification-boundary tests for all 4 outcomes, sessionType-isolation tests (placement evidence excluded from `masteryEvidenceForObjective`, alongside the pre-existing finalAssessment case), retake-storage tests, and a deterministic real-content placement-flow widget test using an overridable RNG-seed provider. Phase 10 (QA pass) added Settings screen tests (locale/theme-mode switching, the reset-progress confirm-and-erase flow) and a `resetProgressForLearner` test proving it clears every progress table for one learner without touching another learner's data or the `learners` row itself — 134 tests passing overall. Phase 10's QA pass also surfaced and fixed several hardcoded-English-string bugs (a genuine bilingual-copy violation, not a testing gap per se) and two real store-blocking bugs the test suite structurally cannot catch without a device: missing Android `RECORD_AUDIO`/iOS `NSMicrophoneUsageDescription` permission declarations — see [SECURITY.md](SECURITY.md) and [TECH_STACK.md](TECH_STACK.md). 2026-09-08: added the "Platform services that must be faked" section — Tier 2 of offline answer evaluation made `MohingoApp` watch `pendingRefinementDrainerProvider` at root, so every test that pumps the full app now needs `connectivityServiceProvider` overridden with `FakeConnectivityService` or it throws `MissingPluginException`; see [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md). Later the same day: every remaining opaque-rubric-string activity across the A1 units, Final Mission and Final Assessment was migrated to a structured `EvaluationSpec`, each with a `test/content/a1_u*_mastery_regression_test.dart`-style proof of real masterability (mirroring `a1_u0_mastery_regression_test.dart`); added the Final Mission/Final Assessment completability coverage to the "Placement/mission/assessment" row below after finding and fixing a real bug that coverage exposed — see [DATA_MODEL.md](DATA_MODEL.md). Later still: fixed a real bug reported live from a real device — the pending-online-refinement drain never triggered for a learner who was online the *entire* session (only triggered at app start and on a connectivity-change edge event, neither of which fires for "already online, just submitted"); then a second real gap the same investigation surfaced — the feedback banner never updated even after the drain resolved it, since it rendered from a one-time local snapshot. Fixed via `latestAttemptProvider`, added the "Online-refinement feedback" row below, and caught (via a real failing test, not a hunch) a whole-second timestamp-precision bug in the fix itself before it shipped. 2026-09-09: added the Learn-tab "Lesson Answer Review" feature — reopening an already-finished lesson now shows a read-only `LessonReviewScreen` walkthrough of the learner's latest answers instead of a blank replay, with an explicit "Practice again" button as the only way back into the real player; see the "Lesson answer review" row below and docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md. Later the same day: the final whole-branch review found and fixed a real bug in that feature — 6 of its 7 activity views collapsed `ActivityAttempt.isCorrect`'s tri-state `bool?` (`true`/`false`/`null`=`notAutoGraded`, i.e. never graded) to a binary in review mode, rendering a `null` (a `write`/`speak` activity with no `accepted` list, an unresolved `previousAnswer:` reference, or any pre-2026-09-08 legacy attempt row) as "Incorrect" — now fixed to a three-way switch, with a `reviewAttempt`-with-`isCorrect: null` test added per view; see the row below._

# Testing

## Levels & expectations

| Level | Tool | Required for | Coverage bar |
|---|---|---|---|
| Unit | `flutter_test` / `package:test` | Curriculum parsing, content indexing, mastery aggregation, repository logic, Riverpod providers/notifiers | All non-trivial logic — see "What must be tested" below |
| Widget | `flutter_test` (`WidgetTester`) | Individual screens/components, especially bilingual (Arabic/English) and RTL/LTR rendering | Key screens: one representative widget per activity type (all 9, including `dialogue` even though the current bundle has no authored instance), unit/level overview, placement/mission/assessment result screens |
| Integration/E2E | `integration_test` package | Critical end-to-end flows on a real device/simulator | The flows listed below |

## What must be tested

- **Curriculum content:** bundle JSON parsing against the real bundle shape; `schemaVersion`/`contentVersion` validation and graceful failure on an unsupported/corrupted asset (never a raw crash); stable-id indexing and unresolved-reference detection (a lesson/activity referencing a grammar/lexicon/chunk/canDo id that doesn't exist); content catalogue availability state (A1 `available`, A2–C2 `comingSoon`, never selectable as if content exists).
- **Progress & mastery:** DB migrations; progress resume after app termination mid-lesson (no duplicate or lost `activity_attempts`); practice-vs-mastery separation (`mode='practice'` activities never count as mastery evidence); Can-Do evidence aggregation per `(canDoId, evidenceSkill, mode)` against `MASTERY_POLICY` (minimum evidence count, minimum score, no single compensating average across required skill groups) — see [DATA_MODEL.md](DATA_MODEL.md); a Unit's "recommended next" resolution never behaves as a hard lock (a learner can navigate to any unit).
- **Placement/mission/assessment:** placement classification-boundary tests confirming all four actionable A1-only outcomes are reachable and the test never fabricates an A2+ result; final-assessment/mission isolation from ordinary training (their attempts never surface through Review, their prompts are never drawn from practice content); retake attempts stored separately from the original; the Final Mission and Final Assessment are actually completable end to end against the real bundle — every writing/speaking/mediation rubric graded via `evaluate()` on a plausible correct answer, fed through `FinalMissionScoring`/`FinalAssessmentScoring` exactly as their screens do, asserting an overall pass (a `form`-type activity's `notAutoGraded` submission must be excluded from that scoring evidence, never left in as a permanently-pending item — see [DATA_MODEL.md](DATA_MODEL.md)).
- **Vocabulary/Grammar:** vocabulary review-scheduling algorithm (whatever documented spaced-review algorithm is chosen); two lexical senses sharing a headword are treated as distinct records (e.g. the bundle's `A1.LEX.PICTURE.N01`/`N02`); marking a vocabulary item confident/reviewed or a grammar item reviewed never flips the related Can-Do's mastered state.
- **Speech:** speech-unavailable and permission-denied fallback to the typed-answer path; a `speak` activity answered via that fallback never records speaking evidence (`evidenceSkill='writing'`, `wasFallback=true` — see [DATA_MODEL.md](DATA_MODEL.md)); no verbatim transcript is persisted after scoring.
- **Online-refinement feedback:** `WriteActivityView`/`SpeakActivityView` must flip from the pending banner to the real Correct/Incorrect result the moment a matching resolved `activity_attempts` row appears — via `latestAttemptProvider`, invalidated by `pendingRefinementDrainerProvider`'s `onItemResolved` — without the learner leaving or re-entering the activity; a resolved row from an *earlier* retry of the same activity must never be shown as this submission's result. Watch for the whole-second precision trap: `attemptedAt` is stored at whole-second granularity, so a millisecond-precision "submitted at" capture must be truncated to seconds before comparing, or a result written in the same wall-clock second as submission gets wrongly treated as stale (see `write_activity_view.dart`'s `_truncatedToSeconds`).
- **Lesson answer review (Learn tab only):** reopening a lesson that has reached its final activity shows `LessonReviewScreen`, not `LessonPlayerScreen` — a lesson that's merely started or mid-way through is unaffected. Every answerable activity view's `reviewAttempt` parameter renders read-only, seeded from the recorded `ActivityAttempt`, and must **never** call `evaluate()` or otherwise recompute correctness/score — the banner always reflects the attempt exactly as recorded, even when it disagrees with what live re-grading of the same answer would produce (a rubric can change after the attempt was recorded). A `notAutoGraded` (never-graded) attempt — `ActivityAttempt.isCorrect` stored as `null`, not `true`/`false` — must render as the neutral "saved for review" treatment in review mode too, exactly like a live `notAutoGraded` submission, never as incorrect. A lesson replayed more than once shows only the latest attempt per activity, and reopening the review screen after a "Practice again" replay reflects that latest attempt, not stale pre-replay data. Out of scope: the Tests tab (Final Mission/Assessment/Placement Test) — a deliberately separate, later decision, see docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
- **Localisation/theming:** Arabic/English locale and RTL/LTR rendering correctness for any screen carrying bilingual content, including mixed-direction text (an Arabic sentence with an embedded English word/phrase must not force the embedded text into RTL); light/dark/system theme and colour-theme selection persist across restarts and apply immediately without one.
- **Offline:** at least one full end-to-end "complete an A1 unit" flow in airplane mode, covering onboarding (local profile creation) → guided path → a lesson → an activity of each broad type → unit state updates, all without any network connectivity.

## Platform services that must be faked

Device-backed plugins have no platform channel to answer in `flutter test`, so any test that reaches one must override its provider with the matching fake — otherwise the test hangs waiting for a reply that never comes, or throws `MissingPluginException`:

- **Speech** (`flutter_tts`, `speech_to_text`, `permission_handler`): override `textToSpeechServiceProvider`/`speechRecognitionServiceProvider`/`speechCapabilityServiceProvider` with `test/features/speech/fake_speech_services.dart`'s fakes for any widget that reads them.
- **Connectivity** (`connectivity_plus`): override `connectivityServiceProvider` with `FakeConnectivityService` (`test/features/activity_engine/fake_connectivity_service.dart`) in **every test that pumps the full `MohingoApp`**, not only tests about online refinement. `MohingoApp` watches `pendingRefinementDrainerProvider` at root, which listens to the real `DeviceConnectivityService`'s platform channel; unmocked, the plugin reports an unhandled `MissingPluginException` on both listen and cancel. `test/widget_test.dart`'s shared pump helper already does this — reuse it rather than re-deriving the override list.
- **Grammar check** (the LanguageTool HTTP call): no test ever makes a real network request. `FakeGrammarCheckService` (`test/features/activity_engine/fake_grammar_check_service.dart`) stands in with a canned result, a canned `GrammarCheckUnavailableException`, and an optional artificial `delay` for exercising overlapping drains. Overriding `grammarCheckServiceProvider` is only needed when the queue actually has rows — an empty `pending_online_refinements` table never reaches the service.

## Performance

No real device or profiler (DevTools timeline, frame-rendering stats, memory snapshots) is available in this dev environment, so frame-rate/jank/memory profiling has not been done — flag this explicitly rather than claiming a performance bar was verified when it wasn't. What has actually been checked:

- **Content parsing/indexing time**, the one cost proportional to the curriculum bundle's size (738KB, ~1,200 leaf records): measured directly (`CourseBundleParser.parse` + `CourseContentIndex.build`, JIT-warmed) at ~9ms total on this dev machine's Dart VM — not a real phone, and not a first-run (un-warmed) number, but a strong signal this isn't a performance risk even accounting for slower mobile hardware, especially since it already runs off the UI isolate via `Isolate.run` (see [ARCHITECTURE.md](ARCHITECTURE.md)) so a slower result would show as a longer splash screen, never a janky frame.
- **No obvious anti-patterns** (rebuilding a whole screen from a single-field state change, an unbounded list with no lazy building, a synchronous DB call on the UI thread) were introduced — Drift's async API and Riverpod's provider-scoped rebuilds are used throughout as intended.

Real profiling (startup time to first frame, scroll jank in the longest lists, memory under a full A1 session) should be one of the first things done once a real Android/iOS device or emulator is available — see the real-device-testing limitation noted throughout this doc and [TECH_STACK.md](TECH_STACK.md).

## What doesn't need tests

- Generated code (Drift schema/DAOs, `freezed`/`json_serializable` boilerplate)
- Trivial getters/simple data classes with no logic
- Third-party package wrappers with no added logic (e.g. a thin call to `speech_to_text`)

## Curriculum package validators (separate from the Flutter test suite)

When `docs/a1-modular-course/` is present in the repo, its own Node-based validators check the *authoring* side (units/registries), not the Flutter app, and should be re-run before trusting any cached quality report or copying a new bundle version into `assets/`:

```
cd docs/a1-modular-course
node tools/validate-a1.mjs
node tools/audit-quality.mjs
node tools/build-a1.mjs
```

## Running tests

```
flutter test                      # unit + widget tests
flutter test integration_test/    # integration/E2E tests (requires device/simulator)
```

## Deferred (post-v1)

Sync-behavior testing (local progress correctly pushing to a remote store when connectivity returns, without duplicating/losing Attempts) does not apply in v1 — there is no sync in v1, see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md). Add this category back once account-based sync is built.

## CI

None configured yet — to be set up once the CI/CD tool is chosen (see [TECH_STACK.md](TECH_STACK.md), currently TBD between Codemagic and GitHub Actions).
