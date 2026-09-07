# Offline Answer Evaluation — Replacing the Unimplemented `evaluation` Rubric System

**Status:** Approved design, ready for implementation planning
**Date:** 2026-09-07

## Context

Investigating why A1-U0 (English Essentials) can never reach "Mastered" found that 2 of its 4 required Can-Do objectives rely exclusively on activities that declare an `evaluation` rubric (e.g. `"evaluation": "non-empty-name"`) instead of `accepted: [...]`. The `evaluation` field is parsed (`FormActivity`/`SpeakActivity`/`WriteActivity` in `lib/content/models/activity.dart`) but never read by any grading code — `write_activity_view.dart`/`speak_activity_view.dart` branch only on `accepted.isNotEmpty`, so any activity that only declares `evaluation` always submits `ActivityCorrectness.notAutoGraded`, which `MasteryAggregationService._scoreOf` scores as `0.0`. That makes the objective mathematically unmasterable.

A bundle-wide grep found this is not U0-specific: 133 activities across all 13 A1 units, the Final Mission, and the Final Assessment declare `evaluation` (vs. 143 using `accepted`). Roughly a third of those 133 are genuinely open-ended writing/speaking paragraphs (e.g. `u5-free-time-message-rubric`), not short structured answers.

Two hard constraints shaped this design, given directly by the product owner:

1. **No paid AI/cloud grading, ever** — the app must cost nothing to run. A free, rate-limited third-party service (their example: DeepL's free tier) is acceptable; a metered LLM API is not.
2. **Open-ended tasks must still count toward mastery** — excluding them from the mastery gate (the simpler option) was explicitly rejected. They must receive real, if imperfect, automated grading.
3. (Existing, non-negotiable, from `CLAUDE.md`) **No learning feature may require network connectivity to function.** A learner who never goes online must still be able to reach "Mastered."

## Goals

- Replace the unimplemented `evaluation` string with a structured, data-driven spec that a small set of reusable Dart evaluators can execute — so a new A2–C2 unit's rubrics are authored as content, never as new app code.
- Grade the ~90 structured-answer rubrics fully offline, instantly, forever.
- Grade the ~40 open-ended paragraph rubrics with real content-awareness offline, refined by a free grammar-quality check when the device is online, without ever blocking or permanently penalizing an offline-only learner.
- Fix the two rubrics that need a persisted learner name (`letter-sequence-from-profile-name` and similar), which today has no backing field at all.

## Non-goals

- No semantic/meaning-level understanding of open-ended answers (no embeddings, no local ML model). Grading open-ended text is keyword/structure-based, not comprehension-based — a known, accepted accuracy ceiling.
- No change to `MasteryPolicy`'s existing thresholds (`minimumObjectiveScore: 0.75`, `minimumEvidencePerRequiredObjective: 2`, etc.) — this design changes how a score is produced, not the policy that consumes it.
- Not building a generalized "any future rubric type" plugin system — the evaluator vocabulary is a small, fixed set (Section: Evaluator types); a genuinely new grading strategy is a new evaluator class, same review process as any other code change.

## Data model: structured evaluation specs

`evaluation` moves from an opaque `String?` to a structured object, on all three activity classes that carry it today (`FormActivity`, `SpeakActivity`, `WriteActivity`):

```json
"evaluation": {
  "type": "keywordChecklist",
  "requiredGroups": [
    ["hi", "hello", "hey"],
    ["free", "weekend", "saturday", "sunday"],
    ["movie", "park", "coffee", "walk"]
  ],
  "minGroupsMatched": 2,
  "onlineRefinement": "grammarCheck"
}
```

Four evaluator types cover all 133 existing rubrics:

| Type | Use | Parameters |
|---|---|---|
| `nonEmpty` | Trivial presence (`non-empty-name`) | none |
| `numericRange` | Extract a number, check range (`valid-age-response`) | `min`, `max` |
| `letterSequence` | Compare spelled input, reusing `answersMatch`'s normalization (`letter-sequence-from-*`) | `reference`: `"profileName"` \| `"previousAnswer:<activityId>"` \| a literal string |
| `keywordChecklist` | Short structured answers **and** open-ended paragraphs | `requiredGroups` (list of acceptable-surface-form lists), `minGroupsMatched`, optional `onlineRefinement: "grammarCheck"` |

`WriteActivity.wordGuide` (`[min, max]`, already a real field) is reused as-is for word-count guidance on `keywordChecklist` — not duplicated into the rubric spec.

`FormActivity.fields` (multiple blanks in one activity) means the dispatcher evaluates per-field when the activity is a `FormActivity`, combining per-field results the same way multi-part `accepted` answers are combined today.

Only rubrics carrying `onlineRefinement: "grammarCheck"` are open-ended paragraphs; every other rubric (the ~90) never touches the network.

Migrating the existing 133 opaque rubric-name strings into this structured shape is a one-time content-authoring pass — candidate specs drafted for review, same review-before-ship pattern the content pipeline already uses for lesson content, not something that ships unreviewed.

## Grading flow

**Tier 1 — structured answers (`nonEmpty`, `numericRange`, `letterSequence`, and `keywordChecklist` without `onlineRefinement`):** evaluated synchronously in `write_activity_view.dart`/`speak_activity_view.dart` at submit time, exactly like `accepted` is today. Produces a real `score`/`isCorrect` immediately; recorded via the existing `ActivityAttemptRepository.recordAttempt` call, no schema change needed for these.

**Tier 2 — open-ended paragraphs (`keywordChecklist` with `onlineRefinement: "grammarCheck"`):**

1. On submit, the local `keywordChecklist` evaluator runs immediately and drives **UI feedback only** (e.g. highlighting a missing expected element) — it is never written as the graded score, per the constraint that these must not count until actually evaluated.
2. The raw answer is queued in a new `pending_online_refinements` table (learner id, activity id, lesson id, Can-Do ids, raw answer, submitted-at, refinement-attempt count) — **not** written into `activity_attempts`. `ActivityAttempts` is insert-only and never updated (see `attempt_tables.dart`), so a queue row, not a placeholder attempt row, is the right home for "not yet graded" state — it keeps `MasteryAggregationService` completely unaware of pending items (no evidence row exists yet, so the objective reads as "needs more evidence," the same as before any attempt was made).
3. The learner sees a clear, bilingual, non-blocking notice ("We'll finish grading this once you're online") and continues the lesson immediately.
4. A `ConnectivityService` (same shape as the existing `TextToSpeechService`/`SpeechRecognitionService` interfaces — real platform implementation, fake in tests) detects connectivity and drains the queue a few items at a time, calling the free public LanguageTool API (`api.languagetool.org`, ~20 req/min soft limit, no API key, free/open-source) for a grammar/spelling pass on each. On success, the grammar signal is combined with the (re-run) local content score into a final result and recorded via one ordinary `recordAttempt` call — an insert, same as any other attempt — and the queue row is removed. This flows through the mastery/progress providers' existing invalidation path (built for the mid-lesson-exit staleness fix), so the UI updates itself without the learner having to re-open anything.
5. On failure (offline, timeout, rate-limited), the queue row's attempt count increments and it's retried on the next connectivity event, with backoff.
6. **Bounded offline fallback:** once a queue row's retry count or age crosses a threshold (exact values decided at implementation — e.g. 5 failed attempts or 14 days), it resolves using the local content-only score as final, via the same `recordAttempt` path, and is removed from the queue. This is what keeps the non-negotiable "no feature may require network to function" rule intact — online refinement is a quality upgrade, never a hard requirement.

No new `ActivityCorrectness` value and no `ActivityAttempts` schema change are needed — pending state lives entirely in the new queue table, and every attempt that eventually reaches `activity_attempts` is a normal, fully-graded row.

## Learner name

Two rubrics need a persisted learner name (`letter-sequence-from-profile-name`), which the `Learners` table has no field for today. Adds:

- A nullable `name` column on `Learners` — the project's first-ever Drift schema migration (`schemaVersion` 1→2, a real `onUpgrade`; nothing has exercised this path before now).
- A one-time onboarding prompt (or a Settings-screen field, if skipped) to capture it.
- If still unset when a `letterSequence`/`profileName` rubric is reached, that rubric falls back to a `nonEmpty` check rather than blocking the learner.

## Error handling

- LanguageTool call fails/times out/rate-limited → queue row retried later, never silently dropped, never blocks lesson progress.
- Device never goes online → bounded fallback (above) guarantees eventual resolution using local-only grading.
- Malformed/unparseable LanguageTool response → treated as a failed attempt (retried), not a crash.
- An activity's `evaluation` spec fails to parse from the bundle (authoring error) → falls back to `notAutoGraded`, exactly as today, rather than throwing — a content bug degrades gracefully instead of breaking the lesson.

## Testing

- Each evaluator (`nonEmpty`, `numericRange`, `letterSequence`, `keywordChecklist`) gets isolated unit tests — pure functions, no Flutter needed, same style as `answer_matching_test.dart`.
- `FormActivity` per-field dispatch gets a dedicated test (multiple fields, mixed pass/fail per field).
- Tier 2's queue lifecycle (submit → pending → refined) and bounded fallback get tests against `FakeConnectivityService`/`FakeGrammarCheckService` (same pattern as `FakeTextToSpeechService`), including the retry-then-fallback path, without any real network call in CI.
- `MasteryAggregationService` tests confirm a pending (queued, not-yet-attempted) open-ended item is indistinguishable from "not yet attempted" for objective/evidence counting.

## Open questions

- **Exact bounded-fallback threshold** (retry count vs. elapsed days, or both) — left to implementation; either is consistent with this design as long as it's finite and reasonably short (weeks, not months).
- **LanguageTool → final score combination formula** (how a grammar-error density maps onto the local content score) — a concrete formula is an implementation detail, not an architectural one; a reasonable starting point is a small penalty per severe error capped so content coverage still dominates the score.
- **Self-hosting LanguageTool later**, if the public endpoint's rate limit proves too tight at scale — explicitly deferred; the public free endpoint is sufficient for MVP and this design doesn't preclude swapping the `GrammarCheckService` implementation later.
