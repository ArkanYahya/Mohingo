> **What this file is:** How the app talks to and treats users — voice, tone, how it handles errors/empty states, and the accessibility bar it must clear. Keeps copy and interaction patterns from feeling like they were written by a different person on every screen.
> **How to use it:** Reference when writing any user-facing copy or interaction (errors, empty states, confirmations). If a new pattern is needed, add it here once decided rather than inventing it locally each time.

_Last verified: 2026-09-19 — added "Tests": the placement test and final assessment don't mark answers while running. Previously verified 2026-09-09 — added the "not answered" empty-state copy introduced by the Learn tab's lesson-answer-review feature; see docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md._

# UX Principles

## Voice & tone

Warm, encouraging, celebratory — never scolding. A learner getting an answer wrong is treated as a normal step, not a failure ("Not quite — here's why" rather than "Wrong"). All user-facing copy is bilingual (Arabic/English) and each language version is written natively for that language's tone, not machine-translated from the other.

## Error messages

- Format/pattern: what happened, in plain language, plus what to do next — no raw exception text or error codes shown to the learner.
- Exercise-level "errors" (wrong answers) are not treated as app errors — they use the correct/incorrect exercise feedback pattern (see [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)), not an error message.
- True app errors (e.g. sync failure, offline when online was required) explain the cause simply ("Couldn't sync your progress — we'll try again when you're back online") and never block the learner from continuing offline work.

## Empty states

Placement test not yet taken / no progress yet: framed as an invitation to start, not a blank/broken screen ("Let's find your starting point" rather than "No data").

Lesson answer review, per-activity: a finished lesson's read-only review screen (Learn tab only) can encounter an activity with no recorded attempt at all — content changed after the lesson was completed, for instance. This renders inside that activity's own chrome (never a generic list item or a raw gap) as a neutral "Not answered" placeholder — no icon or color implying an error, since nothing went wrong; the learner simply never answered it.

## Loading states

Content downloads (new/updated lesson content) show progress, since they may take time on a slow connection; local/cached content renders instantly with no loading state since it's already on-device (this is the offline-first point).

## Confirmations / destructive actions

Confirmation required only for actions that lose progress or data (e.g. resetting progress in Settings, which erases all local mastery evidence and attempt history — see [DATA_MODEL.md](DATA_MODEL.md)). Confirmation copy states what will be lost, plainly, before the action is taken. Retaking the placement test is **not** destructive under the free-access model (see [PRODUCT.md](PRODUCT.md) flow 5) — it's advisory only and never erases existing unit progress, so it needs no confirmation.

## Tests

The placement test and final assessment never tell the learner whether an answer was right while the test is running — no colours, sounds or correct answers, and no listening transcripts — because both are there to measure, and the assessment's items must stay unseen for a retake. Say so before the test starts (the intro's rules note) and after each answer ("Answer saved · You'll see your results at the end"). The final mission is a scenario the learner works through, so it keeps normal right/wrong feedback.

## Accessibility baseline

- Standard: WCAG 2.1 AA
- Non-negotiables:
  - All interactive elements screen-reader labeled in both Arabic and English (VoiceOver/TalkBack)
  - Color contrast ratios met in both light and dark themes (see [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) tokens)
  - Correct/incorrect exercise feedback is never conveyed by color alone — always paired with an icon (check/X) and text
  - Full RTL mirroring for Arabic — layout, icons with directional meaning (e.g. back arrows), and gestures all flip correctly
