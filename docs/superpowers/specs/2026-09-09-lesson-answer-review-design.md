# Lesson Answer Review — showing a learner their past correct/incorrect answers

**Status:** Approved design, ready for implementation planning
**Date:** 2026-09-09

## Context

Reported directly by the product owner using the app: reopening an already-completed lesson from the Learn tab drops the learner straight back into a blank, fully live lesson — every activity is answerable again, with no way to see what they answered last time, whether it was right, or what the correct answer was.

This replay-from-scratch behavior is itself intentional and already documented (`lesson_player_screen.dart`'s class doc comment, `docs/DATA_MODEL.md`): `activity_attempts` is insert-only, so revisiting a finished lesson appends fresh evidence rather than corrupting history, and free repetition is good pedagogy for a language app. That part is not changing.

What's missing is the other half: nothing anywhere lets a learner actually see that history. The 2026-09-04 UI redesign (`2026-09-04-ui-navigation-redesign-design.md`) added a one-time tally screen (`_LessonCompleteScreen`) shown immediately after finishing a lesson, but it's discarded the moment the learner navigates away — there is no way to reach it, or any per-activity detail, again later. The unit/lesson `StatusIndicator` badge (`mastered`/`needsReview`/etc.) signals *that* something needs attention, never *which* answer was wrong or what the right one was.

Scope check: this is about the **Learn tab only** — the Tests tab (Final Mission, Final Assessment, Placement Test) has the same "no review, just a fresh retake" gap, but that was raised and deliberately deferred in the same conversation as a separate, later decision; nothing here touches those three screens.

## Goals

- Reopening a lesson the learner has genuinely finished shows a read-only walkthrough of their last answer to every activity — correct/incorrect, and the correct answer where one exists — by default.
- An explicit, unmissable way to start a fresh replay is always present from that screen.
- Visual consistency: a reviewed answer should look like the same activity type it always does (a match activity's review still shows paired items, not a raw JSON dump), not a generic bolted-on list.
- A lesson that's not started, or only partway done, is completely unaffected — it still resumes exactly as it does today.

## Non-goals

- The Tests tab (Final Mission/Assessment/Placement Test) — explicitly out of scope, a separate future decision.
- Showing more than the latest attempt per activity — a learner who replayed a lesson three times sees only their most recent answer per activity, not a full attempt-by-attempt history. Revisit later if this proves insufficient.
- Any change to replay/insert-only history semantics — `recordAttempt` stays insert-only, replay still appends fresh evidence exactly as today.
- Re-grading a past answer against a possibly-changed rubric — review always shows the `isCorrect`/`score` actually recorded at the time, never a freshly recomputed one.

## Design: entry flow

- `UnitOverviewScreen`'s lesson row: tapping a lesson whose progress shows it reached its final activity (i.e. genuinely finished — the same signal `_resolveStartIndex` in `lesson_player_screen.dart` already uses to distinguish "finished" from "mid-lesson") navigates to a new `LessonReviewScreen` instead of `LessonPlayerScreen`.
- Tapping a lesson that's not started, or resumable mid-lesson, is unchanged — straight into `LessonPlayerScreen`, resuming where the learner left off exactly as today.
- `LessonReviewScreen` renders every activity in the lesson, each shown read-only with its latest recorded answer (see below), plus one `FilledButton` — **"Practice again"** — that navigates into the real `LessonPlayerScreen`, replaying from activity 0 exactly as reopening a finished lesson does today. Nothing about the replay mechanism itself changes; this button is the only door to it now, rather than it being the automatic default.

## Design: data loading

`LessonReviewScreen` loads via `ActivityAttemptRepository.attemptsForLessons` (existing method, already used elsewhere) for the one lesson, then reduces to "latest attempt per `activityId`" — the exact same reduction `lesson_player_screen.dart`'s `_rehydratePreviousAnswers` already performs today (keep the row with the greatest `attemptedAt` per activity id). No new repository method needed.

## Design: per-activity-view review mode

Every activity view already has two states: live/interactive (waiting for an answer) and submitted (banner shown, controls locked, correct/incorrect visible, via its own `ActivitySubmission?` field going non-null). Review mode enters a view directly into the submitted state instead of reaching it through live interaction:

- Every activity view that can actually be answered (`ChoiceActivityView` — covers both `audioChoice` and `textChoice` via its two named constructors — `GapActivityView`, `MatchActivityView`, `OrderActivityView`, `WriteActivityView`, `SpeakActivityView`, `FormActivityView`) gains one new optional constructor parameter, `reviewAttempt` (an `ActivityAttempt?`, default `null` — every existing call site and every existing test is unaffected). `DialogueActivityView` takes no answer today (per `lesson_player_e2e_test.dart`'s own driving helper: "no input required") and needs no review-mode change — there's nothing to show.
- When `reviewAttempt` is non-null: the view decodes `reviewAttempt.rawAnswer` back into the same internal shape it already uses for live selection (`_selected`, `_userMatches`, `_placed`, the text controller's text, the form's field map), seeds that state at `initState`, and renders straight into its existing "already submitted" branch — no live interaction is ever offered.
- The view uses `reviewAttempt.isCorrect`/`reviewAttempt.score` directly for the feedback banner. It does **not** call into `evaluate()` or any live grading path — this is a display of what was actually recorded, never a re-judgment.
- `SpeakActivityView` skips its microphone-capability check (`_checkCapability` in `initState`) entirely in review mode — nothing is being recorded, so there's no reason to touch speech services at all.
- `onSubmitted` is never invoked in review mode (nothing new is being recorded); `LessonReviewScreen` passes a no-op callback when constructing each view via `buildActivityView`, which itself gains the same optional `reviewAttempt` passthrough parameter.
- `FormActivityView` in review mode shows the saved field values with a neutral "Saved" treatment — forms are `notAutoGraded` today and stay that way; review must not invent a correct/incorrect state that was never computed.
- An activity with no attempt at all in the loaded data (shouldn't happen for a lesson recorded as finished, but data can be messy — e.g. content changed after the attempt was recorded) renders a neutral "not answered" placeholder rather than crashing or guessing.

## Testing

- One widget test per activity type confirming `reviewAttempt` renders the historical answer read-only (correct answer visible where applicable, no interactive controls reachable, no live grading triggered).
- One end-to-end test: complete a real lesson, replay it with a different (better or worse) answer on one activity, open `LessonReviewScreen`, and confirm it shows the *second* (latest) attempt's result, not the first.
- A widget test confirming a not-started or mid-lesson unit's row still routes to `LessonPlayerScreen`, unaffected.

## Open questions

- Exact visual treatment for the "not answered" placeholder and the form's "Saved" state — left to implementation-time judgment within existing `ActivityFeedbackBanner`/design-token conventions, not a decision that needs to block planning.
