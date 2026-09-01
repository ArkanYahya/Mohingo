# 0003: On-device speech/writing assessment for MVP; cloud AI grading deferred

**Status:** Accepted

## Context

The MVP covers all 4 CEFR skills, including speaking and writing, both of which need some form of assessment to give the learner feedback and to gate progression (see [DATA_MODEL.md](../DATA_MODEL.md)'s `Attempt` entity). High-quality assessment of free speech and free text is a natural fit for cloud AI (LLM-based grading, cloud speech-to-text with pronunciation scoring) — but that conflicts directly with the offline-first, no-custom-backend decision in [0001](0001-offline-first-firebase-only-backend.md): a cloud AI call requires network connectivity at the moment the learner does the exercise, even though the rest of the app works offline.

## Decision

For the MVP, speaking and writing assessment run entirely on-device: speaking uses the phone's native speech-to-text engine (via the `speech_to_text` Flutter package) to transcribe and check against expected answers; writing uses rule-based/heuristic checks rather than AI grading. Both are simpler and less pedagogically nuanced than cloud AI grading would be, but require no network connection and no server-side component.

## Alternatives considered

- **Cloud AI grading at runtime (e.g. Firebase Cloud Functions calling an LLM/speech API)** — better assessment quality, but violates the "fully offline" MVP requirement and adds a serverless component to build and pay for before the core product is validated. Deferred to post-MVP — see [ROADMAP.md](../ROADMAP.md), non-content item 1.

## Consequences

- Keeps the MVP fully offline and free of any runtime cloud AI dependency or cost.
- Caps assessment quality for speaking/writing below what an LLM-based grader could provide — accepted knowingly for the MVP; the gap should be re-evaluated once real learners have used the on-device version (see open question in [PRODUCT.md](../PRODUCT.md) and [ROADMAP.md](../ROADMAP.md)).
- When cloud AI grading is added later, it will need to work as an optional enhancement layered on top of (not a replacement requirement for) the offline path, to preserve the offline-first guarantee established in [0001](0001-offline-first-firebase-only-backend.md).
