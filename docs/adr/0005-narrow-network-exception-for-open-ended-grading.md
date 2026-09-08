# 0005: A narrow, bounded network exception for open-ended answer grading

**Status:** Accepted

## Context

[ADR 0004](0004-local-only-v1-no-firebase-backend.md) established that v1 "requires no network permission or background network call for any learning feature." Tier 1 of the offline-answer-evaluation work (see docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md) built a fully offline, non-AI grading system for structured answers, but deliberately deferred ~40 genuinely open-ended writing/speaking rubrics — no offline technique can meaningfully judge free-form paragraph quality beyond keyword coverage.

The product owner's explicit, self-imposed constraints for this gap (given directly, not inferred) were: no paid AI API, ever (the app must cost nothing to run); a free, rate-limited third-party service is acceptable (their own example: DeepL's free tier); open-ended tasks must still count toward mastery, not be silently excluded; and — per ADR 0004, unchanged — a learner who never goes online must still be able to reach "Mastered."

This is the first time anything in the app sends learner-authored content off the device. It needed its own decision, not a silent extension of Tier 1's scope.

## Decision

A narrow, bounded exception to ADR 0004: when the device is online, an open-ended writing/speaking answer (only the ~40 rubrics explicitly marked `onlineRefinement: "grammarCheck"`) may be sent to the free public LanguageTool API (`api.languagetool.org`) for a grammar/spelling-quality check — a rule-based checker, not an AI/LLM, no API key, no cost. This is strictly a quality upgrade, never a requirement: every such answer is graded locally first (content-coverage score), queued, and — per `docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md`'s Tier 2 — resolved via the bounded local-only fallback if the device never goes online. ADR 0004's actual guarantee ("no network call is *required*") still holds exactly as written; what's new is that the *capability* now exists in the codebase.

The learner sees a message when the answer is submitted indicating it will be checked further once they are online — a bilingual, non-blocking notice on the submission itself (see the Tier 2 plan's Task 6). This is not a disclosure of which service performs the check or that the answer leaves the device; it indicates only that additional grading will occur when online and a fallback local-only grade is available if they never go online.

## Alternatives considered

- **Keep the exclusion Tier 1 shipped with (never grade open-ended tasks at all)** — rejected; the product owner explicitly required real credit for these, not exclusion, when this was first raised.
- **A cloud AI/LLM grading service** — rejected outright per the product owner's own constraint; conflicts with `docs/TECH_STACK.md`'s existing "Cloud-based AI grading... rejected" entry, which this ADR does not reverse (LanguageTool is a deterministic, rule-based grammar/spellchecker, not an AI model).
- **Self-hosting LanguageTool** — considered, deferred: the free public endpoint is sufficient at v1's scale; self-hosting is a pure implementation swap behind the same `GrammarCheckService` interface if the public endpoint's rate limit ever proves too tight.

## Consequences

- `docs/SECURITY.md`'s "no network permission or background network call is required" and "no data leaves the device" statements now carry one explicit, scoped exception — updated in the same change as this ADR, not left to drift.
- The app declares internet-access capability at the platform level for the first time: Android requires declaring the `INTERNET` permission in its manifest (a build-time declaration, not a runtime prompt the learner sees); iOS needs no equivalent change (outbound HTTPS calls don't require an Info.plist entitlement on iOS).
- A learner's open-ended answer text (never any other PII, never audio, never a speech transcript verbatim — see `docs/SECURITY.md`'s existing "never logged" list, unaffected) may leave the device, only when: the rubric is one of the ~40 explicitly marked ones, the device is online, and the learner has been shown the disclosure notice.
- Does **not** reverse `docs/TECH_STACK.md`'s rejection of cloud-based AI grading, and does not open the door to one — a genuinely new AI-grading proposal still needs its own ADR.
