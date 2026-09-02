> **What this file is:** What must be tested, at what level, and how to run it. Keeps test coverage expectations consistent instead of depending on whichever session happens to be writing a feature.
> **How to use it:** Check before adding a feature — what test(s) does this convention require? Update the commands section the moment the test setup changes so it never goes stale.

_Last verified: 2026-09-02 — expanded coverage list for the real curriculum bundle, the mastery-evidence model, and the local-only v1 (sync testing deferred); see [ADR 0004](adr/0004-local-only-v1-no-firebase-backend.md)._

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
- **Placement/mission/assessment:** placement classification-boundary tests confirming all four actionable A1-only outcomes are reachable and the test never fabricates an A2+ result; final-assessment/mission isolation from ordinary training (their attempts never surface through Review, their prompts are never drawn from practice content); retake attempts stored separately from the original.
- **Vocabulary/Grammar:** vocabulary review-scheduling algorithm (whatever documented spaced-review algorithm is chosen); two lexical senses sharing a headword are treated as distinct records (e.g. the bundle's `A1.LEX.PICTURE.N01`/`N02`); marking a vocabulary item confident/reviewed or a grammar item reviewed never flips the related Can-Do's mastered state.
- **Speech:** speech-unavailable and permission-denied fallback to the typed-answer path; a `speak` activity answered via that fallback never records speaking evidence (`evidenceSkill='writing'`, `wasFallback=true` — see [DATA_MODEL.md](DATA_MODEL.md)); no verbatim transcript is persisted after scoring.
- **Localisation/theming:** Arabic/English locale and RTL/LTR rendering correctness for any screen carrying bilingual content, including mixed-direction text (an Arabic sentence with an embedded English word/phrase must not force the embedded text into RTL); light/dark/system theme and colour-theme selection persist across restarts and apply immediately without one.
- **Offline:** at least one full end-to-end "complete an A1 unit" flow in airplane mode, covering onboarding (local profile creation) → guided path → a lesson → an activity of each broad type → unit state updates, all without any network connectivity.

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
