# On-device grading of free answers — a meaning signal for everyone, an optional AI pack for feedback

**Status:** Proposed design for the product owner's review (2026-10-22). Decision record: [ADR 0011](../../adr/0011-on-device-ai-for-free-answers.md). No code yet.
**Date:** 2026-10-22

## Context

The owner wants the app to grade a learner's free answers — `write` tasks and `speak` tasks, in lessons and in review — by what they mean, not only by which words they contain, and to tell the learner why an answer missed. The answers to the design questions, recorded in ADR 0011: free answers first; an optional download of hundreds of megabytes is fine; reference phone iPhone 11/12; a model may adjust the mastery score within bounds but never set it; the Final Assessment stays deterministic; Arabic explanations are a bonus.

What exists today, and is kept:

- `evaluate()` (`lib/features/activity_engine/domain/evaluation/evaluator.dart`) grades a `keywordChecklist` by the share of required groups covered, measured against `minGroupsMatched`; the result is `isCorrect`/`score` on an insert-only `activity_attempts` row.
- A rubric marked `onlineRefinement: "grammarCheck"` is queued in `pending_online_refinements` and drained by `PendingRefinementDrainer`, which combines the local score with LanguageTool's error density (`0.7 × local + 0.3 × grammar`) or falls back to the local score after 5 attempts / 14 days.
- A spoken transcript is graded as said (`SpokenAnswer`, ADR 0009); the typed fallback as written.
- The level gates require a rubric on every mastery speak/write task and that every model answer (`accepted`) passes it.

## Decision summary

1. **Layer 1, bundled, deterministic — the meaning signal.** A small English sentence encoder (candidate: `all-MiniLM-L6-v2`, int8, ~23 MB; chosen at implementation) runs on the device through an ONNX runtime. For a `write` or `speak` task with model answers it yields `meaning ∈ [0, 1]`: the highest cosine similarity between the answer and any model answer, mapped through two thresholds (below the low one 0, above the high one 1, linear between) fixed at implementation against real A1/A2 answers.
2. **Layer 2, downloaded, optional — the AI pack.** A 1–2 B-parameter instruction model at 4-bit quantisation (candidates: Gemma 3n E2B through MediaPipe LLM Inference / `flutter_gemma`; Qwen2.5-1.5B through `llama_cpp_dart`), chosen by a spike on the reference phone. Given the task prompt, the model answers and the learner's answer, it returns one JSON object: `{"meaningOk": bool, "grammarIssues": int, "explanationEn": string, "explanationAr": string}`. Greedy decoding, temperature 0, a fixed prompt template, a hard timeout.
3. **One combination rule, bounded.**

   ```
   base      = rubric score (as today)
   adjust    = +0.25 × meaning          (Layer 1; only when base < 1)
             − 0.25 × grammarPenalty    (pack, or LanguageTool for learners without it)
             + 0.10 × (meaningOk ? 1 : −1)   (pack only)
   adjust    = clamp(adjust, −0.25, +0.25)
   final     = clamp(base + adjust, 0, 1)
   ```

   `grammarPenalty` is today's density mapping (`min(1, errors/words × 4)`). The total adjustment never exceeds a quarter of the scale, so a rubric score of 0 cannot pass and a rubric score of 1 cannot fall below 0.75. The pass bar stays `0.75`. The LanguageTool weight drops from 0.3 to 0.25 so that both paths obey the same bound.
4. **Where it applies.** Lessons, quick practice and the review tab's speak/write activities. **Not** the Final Assessment, the Final Mission or the placement test: they keep rubric-only grading, unchanged in code.
5. **Model answers become required content.** Every mastery `speak`/`write` task carries at least one `accepted` model answer (today A2 has none across its 144; A1 is counted at implementation). `level_answerable_test.dart` gains the rule. The existing rule that each model answer passes its own rubric stays.
6. **Explanations are shown, never scored.** When the pack produced one, the feedback panel adds an "Explanation" block under the verdict, English first and Arabic when present, with a one-line "Generated on your phone" / "مُولَّد على هاتفك" label. Review mode shows the stored explanation; nothing is regenerated.
7. **The pack lives in Settings → Listening & speaking → Smart feedback / ملاحظات ذكية**: its size, Download (Wi-Fi suggested), a progress line, Delete. Hosted on the project's Firebase Storage, read-only, versioned (`packs/<name>-<version>/`), with its licence text inside the pack. Downloading is the only network use the feature has.

## Non-goals

- Grading the capstones or the placement test with any signal beyond the rubric.
- Free conversation with the model, pronunciation scoring, a local speech recogniser. Each is its own decision.
- Shipping the language model inside the app binary, or requiring the pack for anything.
- Translating explanations: the model writes each language; the app never translates one from the other.

## Data flow

**Submit (write or speak view):** `evaluate()` returns the rubric result as today → `MeaningSignalService.similarity(answer, modelAnswers)` (Layer 1, synchronous, a few milliseconds) → if the rubric is marked for refinement **or** the pack is installed, the submission is queued exactly as online refinement is today, with the Layer 1 signal stored on the queue row → otherwise the combined score is written at once.

**Drain (`PendingRefinementDrainer`):** for each row, in order — the installed pack (`LocalJudgementService.judge(...)`, with timeout) → else LanguageTool when online and the rubric allows it → else the bounded fallback as today. The result is one `activity_attempts` insert, `criteriaScores` carrying `{"rubric": …, "meaning": …, "grammar": …, "judgement": …, "pack": "<name>-<version>"}` and the explanation text, and the usual `refreshUnitProgress`.

A pack that fails (out of memory, timeout, malformed JSON) counts as unavailable for that row: the drain moves on to the next source, and after three failures in a session the pack is marked unhealthy until the next launch. Nothing is shown as an error.

**Privacy:** every signal is computed on the device. A spoken transcript may be judged by the pack (local); it still never goes online — `online_refinement_boundary_test.dart` is unchanged and still passes.

## Layering

- `lib/features/activity_engine/domain/evaluation/`: `MeaningSignalService` and `LocalJudgementService` interfaces (platform implementations in `data/`, fakes in `test/`), the combination rule as a pure function (`combineSignals`), the drain gaining its local source.
- `lib/features/settings/`: the pack row and its controller; `lib/features/ai_pack/` for download, verification (size and checksum), storage under the app's support directory, and health.
- `lib/content/`: untouched except the gate reading `accepted` where it already does. The embedding model is a Flutter asset listed in `pubspec.yaml`.

## Testing

- `combineSignals` as data: the bounds (0 base never passes, 1 base never fails), each signal's weight, clamping, the absent-signal cases.
- Drain: pack first, then LanguageTool, then fallback; a failing pack skipped; health after repeated failures; the explanation stored and surfaced; `FakeLocalJudgementService` and `FakeMeaningSignalService` beside the existing fakes.
- Views: the explanation block appears only with a judgement, is labelled, and never changes the verdict; review mode shows the stored text.
- Gates: a model answer on every mastery speak/write task; with the real embedding model, every model answer scores ≥ 0.75 and a fixed off-topic sentence scores < 0.75 on every such task (run as a `test/content/levels/` gate if the ONNX runtime loads under `flutter test`, otherwise as a Dart tool run before release, and the doc says which).
- Device checklist (owner, iPhone 11/12 and one mid-range Android): pack download and delete; a judgement within the timeout; memory with the pack loaded; airplane mode end to end.

## Phasing

1. **Phase A — this environment:** ADR 0011 and this spec; Layer 1 code with the combination rule and fakes; the gate and the model answers A2 needs; the drain's local source behind the `LocalJudgementService` interface; the Settings row; docs per CLAUDE.md's table. The real embedding model is wired and verified on the owner's phone.
2. **Phase B — after a device spike:** the pack: model and library chosen from the spike's speed and memory numbers on the reference phone, hosting, the explanation block, Arabic quality judged by the owner before it is shown.

## Open questions

- The two similarity thresholds, and whether `meaning` should also look at the rubric's required groups when a task has only one model answer.
- Firebase Storage versus the stores' on-demand assets for the pack: Storage is one path for both platforms; Play Asset Delivery and iOS Background Assets are free of egress cost. Decide at Phase B with the pack's real size.
- The pack's licence (Gemma terms of use versus Apache 2.0 for Qwen) once the spike picks the model.
