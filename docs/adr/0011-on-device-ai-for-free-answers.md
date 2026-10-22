# 0011: Free answers are graded on the device — a bounded signal over the rubric, and an optional AI pack for feedback

**Status:** Proposed (2026-10-22) — written for the product owner's review; nothing in `lib/` implements it yet. Design: docs/superpowers/specs/2026-10-22-on-device-free-answer-grading-design.md.

## Context

A learner's free answer — a written paragraph, or a spoken turn as the recogniser transcribed it — is graded today by a `keywordChecklist`: the answer must mention enough of the listed words ([ADR 0003](0003-on-device-speech-writing-assessment-for-mvp.md), the 2026-09-07 offline-answer-evaluation design). That has three gaps the owner wants closed:

1. The right thing said in other words fails, and the listed words strung into a wrong sentence passes. The grader reads surface forms, not meaning.
2. The only quality signal beyond keywords is the free public LanguageTool API ([ADR 0005](0005-narrow-network-exception-for-open-ended-grading.md)): 59 writing tasks, online only, and abandoned after five tries or fourteen days. Nothing a learner *says* may take that path.
3. Nobody tells the learner *why* an answer missed. The panel says "Not quite" and shows a model answer.

The constraints are the project's standing ones. No learning feature may require the network (CLAUDE.md). No paid AI API, ever: the app must cost nothing to run (the owner's rule, recorded in ADR 0005). Cloud AI grading at runtime is rejected in `docs/TECH_STACK.md`. Nothing a learner says leaves the device, and no key ships in the binary (`docs/SECURITY.md`). The 2026-09-07 design listed "no embeddings, no local ML model" as a non-goal; this ADR is the decision that changes it. Grading is deterministic and the level gates prove every unit masterable through the real evaluator ([ADR 0007](0007-one-standard-for-every-level.md)); the Final Assessment measures rather than teaches (`docs/UX_PRINCIPLES.md`, Tests).

The owner's answers on 2026-10-22, which this ADR records: the problem to solve first is free answers; an optional download of hundreds of megabytes is acceptable; the reference phone is an iPhone 11 or 12 (4 GB of memory); a model's judgement may move the mastery score only within bounds, never set it; the Final Assessment stays on deterministic rules; an Arabic explanation is a bonus, not a requirement.

## Decision

1. **Two layers, and the second is optional.** A deterministic **meaning signal** ships inside the app for every learner. An **AI pack** — a small language model the learner downloads once from Settings — adds a judgement of the answer and a written explanation. Without the pack the app grades better than today; with it the learner also gets feedback. No learning feature depends on the pack, and nothing waits for a download.
2. **The rubric still grades; a signal only adjusts.** The rubric's score is the base. Every other signal — meaning similarity to the task's model answers, grammar quality, the pack's judgement — moves it by a bounded amount, at most a quarter of the scale in total, and the result is clamped to `[0, 1]`. An off-topic answer cannot be rescued and a right answer in other words cannot be failed by its wording alone. The pass bar (0.75) does not change.
3. **The meaning signal is a sentence-embedding similarity**, computed on the device with a small English encoder (tens of megabytes, bundled as an asset, deterministic), between the answer and the task's model answers. It therefore needs a model answer on every mastery `speak`/`write` task: that becomes a level-standard rule (`docs/LEVEL_STANDARD.md`, Gradeable), and the content work to meet it is part of this change.
4. **The AI pack is a download, never part of the app binary.** A 1–2 billion-parameter instruction model at 4-bit, chosen at a device spike on the reference phone (candidates: Gemma 3n E2B, Qwen2.5-1.5B), run through an on-device inference library. Hosted on the project's own Firebase Storage (the first use of it; [ADR 0001](0001-offline-first-firebase-only-backend.md)'s "Firebase only" holds) or the stores' on-demand asset mechanisms. Greedy decoding, a fixed prompt, a JSON answer; its version is recorded on every attempt it touched. The pack is deletable from Settings.
5. **Capstones and placement are untouched.** The Final Assessment, the Final Mission and the placement test keep today's rubric-only grading. They measure; the signals are for learning.
6. **Explanations are feedback, not grade.** The pack writes a short explanation in simple English and, when it can, in Arabic. It is labelled as generated, shown after the verdict, and never read by mastery.
7. **The network exception narrows rather than widens.** A learner with the pack never calls LanguageTool: the pack's grammar judgement resolves the queue locally. A learner without it keeps ADR 0005's behaviour unchanged. Spoken transcripts may be refined *locally* by the pack — nothing leaves the device — and `online_refinement_boundary_test.dart` keeps forbidding the online path for them.

## Alternatives considered

- **Cloud AI grading (a Cloud Function calling an LLM)** — rejected, as before: it costs money per answer and needs the network at the moment of answering.
- **The system's own model (Gemini Nano through ML Kit, Apple Foundation Models)** — free and zero download, but present only on recent flagship phones and absent on the reference iPhone 11/12 for the Apple case. Not something the app can rely on for its audience; it may become a second backend for the pack later.
- **A language model inside the app binary** — rejected: 0.5–1 GB in every install, past the stores' 200 MB mobile-data thresholds, for a feature many learners will not use. ADR 0008 rejected an on-device engine for the same reason.
- **The model's judgement as the grade** — rejected by the owner. A model gives the same answer different scores on different days, cannot be proved masterable by the gate suite, and would make "mastered" mean something no test can check.
- **A bundled grammar-correction model instead of the pack's grammar judgement** — considered; 60–250 MB in every install to replace a free online call that already has an offline fallback. Kept as an option if the pack proves too heavy for the audience's phones.
- **Keyword lists written more generously** — the cheapest fix and already the practice; it cannot express "the same meaning in other words", which is the gap.

## Consequences

- Every mastery `speak`/`write` task needs a model answer: A2 has none today (144 tasks); A1's count is taken at implementation. The gate already requires a model answer to pass its own rubric, and will require one to exist.
- The 2026-09-07 design's "no embeddings, no local ML model" non-goal is superseded. `docs/TECH_STACK.md` gains an on-device inference dependency and the embedding model as an asset; `docs/SECURITY.md` records that nothing new leaves the device and that the pack is served, not bundled; `docs/ROADMAP.md`'s item 1 (cloud AI grading) is replaced by this; `docs/DATA_MODEL.md` records the signals written into `activity_attempts.criteriaScores`. All of it in the change that lands the code, per CLAUDE.md's definition of done.
- The app grows by the embedding model (tens of megabytes) for everyone, inside the 200 MB threshold with today's audio; the pack adds nothing to the install.
- Grading stays deterministic where mastery is decided: the rubric and the embedding are both deterministic, and the pack's contribution is bounded. The level gates gain a rule that a model answer scores at least the pass bar and an off-topic answer scores below it, with the meaning signal on.
- A phone that cannot run the pack — too little memory, or a judgement slower than a few seconds — degrades to the first layer: no judgement, no explanation, the queue falls back as it does today. Nothing is shown as an error.
- Arabic explanations are generated, not written by a person; the bilingual rule's "each language written natively" is met only as far as the model manages, which is why they are a bonus and labelled generated.
- Not verified on a device from this environment, like every other device-dependent guarantee (README, Known limitations). The pack's model, library and speed are decided by a spike on the owner's iPhone, and iOS still needs its own Firebase registration and a Mac to build.
