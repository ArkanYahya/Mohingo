# 0014: Free answers are read part by part by a small inference model — the language-model pack is not built

**Status:** Accepted (2026-10-24). The owner approved the recommendation after the device spike's fourth run, and Phase B began the same day on `ccr-3aef6bc0-xt12aw` under this decision. Supersedes decisions 4 and 6 of [ADR 0013](0013-on-device-ai-for-free-answers.md) (the downloadable 1–2 billion-parameter language model, and its generated explanations); decisions 1, 2, 3, 5 and 7 of that ADR stand. Evidence: `tool/ai_pack_spike/results/`.

## Context

ADR 0013 set two layers for grading a learner's free answer: a deterministic meaning signal for everyone, and an optional downloadable language model to judge the answer and explain it. It left the model, the library and the feasibility to a spike on a phone. The spike ran on 2026-10-23 and 2026-10-24 on the owner's Galaxy S24 Ultra (11 GB of memory, a 2024 flagship — a best case against the reference iPhone 11/12 with 4 GB), with 22 fixed learner answers whose right verdict a teacher would not dispute.

What it found, run by run:

| Engine | Verdicts right of 22 | Time per answer | Memory |
|---|---|---|---|
| Gemma 3 1B, verdict-first prompt | 11 (yes to all 22) | 14.8 s | 1.4 GB |
| LFM2.5 1.2B, checks-then-verdict prompt | 11 (yes to all 22; copied the prompt's example) | 18.3 s, then 6.0 s with the right CPU kernels | 1.2–1.7 GB |
| LFM2.5 1.2B, per-part booleans | 13 (judged the task's shape, not the answer; copied the model answer) | 6.0 s | 1.7 GB |
| Qwen2.5 1.5B, per-part booleans, no model answer shown | 15 (real negatives with reasons; yes to "Yes.", to the echoed prompt, to the habit, to the wrong item) | 7.5 s, half of it JSON-grammar sampling | 2.2 GB |
| **MobileBERT-MNLI, a natural-language-inference cross-encoder, one statement per part** | **17, with naive statements; four of the five misses were the statements' wording** | **28 ms** | **0.3 GB, 25 MB on disk** |
| DistilBERT-MNLI | 14 | 22 ms | 0.4 GB |

No language model at a size a phone can hold found a single grammar mistake in 22 answers, including "I like swim and I love read books. I no like run." Every one of them opened its explanations with praise or copied text it had been shown. The inference model made the discriminations they missed: a missing dislike (entailment 0.04, contradiction 0.65), an off-topic sentence (neutral 0.92), "Go away." as not polite (contradiction 0.73), a habit as not last weekend (0.78), the wrong item (0.99). Its misses were statements that asked about the task's situation ("…about the friend's volunteering") rather than the answer's content, which is an authoring rule, not a model limit.

The owner's rules are unchanged: no paid AI, nothing a learner says leaves the device, a model may move the mastery score only within bounds, the capstones stay deterministic, and an Arabic explanation is a bonus. Two more facts weighed: the bilingual rule requires each language written natively, which a generated Arabic explanation (Bengali and Chinese appeared where Arabic was asked) cannot promise; and a 25 MB model can be bundled, so the feature reaches every learner without a download or a connection.

## Decision

1. **Meaning is read per rubric part by a bundled inference model, not judged by a language model.** Each `keywordChecklist` group gains a *meaning*: a plain English statement of what an answer that meets the group says (`says`), plus the part's name for the learner in English and Arabic (`en`, `ar`). The on-device natural-language-inference model (MobileBERT fine-tuned on MNLI, int8, ~25 MB, `assets/models/nli/`) scores the learner's answer against each statement; a group is met by its keywords *or* by entailment at or above a fixed threshold. The meaning signal of ADR 0013 becomes the share of groups met, with the same weight and bound: an answer that says one part in the rubric's words and the other in its own reaches the pass bar; an answer that says neither stays at zero; one that leaves a part out cannot pass on the signal.
2. **The similarity signal stays as the fallback** for a task whose groups have no meanings yet, so the two levels keep grading while meanings are authored, A1 first. The level standard gains the rule (`docs/LEVEL_STANDARD.md`, Gradeable) and the gate the check; a level's coverage is declared, with a reason, until it is complete.
3. **Statements describe the answer, never the situation.** "The speaker says one thing they do not like." — not "…at work", not "…about the friend's volunteering". The spike's four wording misses are the rule's origin. Where a part is a count (three sentences), code counts; a model is not asked to.
4. **Explanations are templated, written by people.** The feedback names the parts an answer met neither way, in the content's own `en`/`ar` labels, inside one sentence of app copy per language. Both languages are built at submission and stored with the attempt. Nothing is labelled "generated", because nothing is.
5. **Grammar is a separate, later model.** No phone-size language model found a mistake, so grammar is not asked of one. The online LanguageTool path of ADR 0005 stays exactly as it is for the writing tasks marked for it; a small grammar-correction model, downloaded on request, is the next candidate and the Settings row ("Grammar check, offline", coming soon) now names it. The `LocalJudgementService` seam in the drain is kept for it.
6. **The language-model pack is recorded as tried and not chosen** at phone size. The spike (`tool/ai_pack_spike/`) stays in the repository as the evidence and the instrument; it is not shipped and nothing in `lib/` imports it. A larger device class or a better small model would be a new spike, not a reversal of this ADR by default.
7. **Capstones and placement remain untouched**, as ADR 0013 decided: the Final Assessment, the Final Mission and the placement test grade on the rubric alone.

## Alternatives considered

- **A larger language model (Qwen2.5 3B, 2.1 GB)** — on the list for the owner's 11 GB phone to find the quality ceiling, not run yet; even if it reads well, it does not fit the reference phone, so it could only ever be a pack for high-end devices, which is a different product.
- **A language model for explanations only, with NLI for the verdict** — rejected for now: the explanations it wrote were confidently wrong ("I like swim … grammatically correct") and in the wrong script, and would still cost 1–2 GB and seconds per answer for a sentence the template says better.
- **Per-group keyword lists written more generously** — ADR 0013's reason stands: it cannot express "the same meaning in other words".
- **Zero-shot classification with the same model, labels instead of statements** — the same model, a less controllable prompt; the statement form is what the spike measured.
- **A multilingual NLI model that could read an Arabic answer** (mDeBERTa-XNLI) — tempting, but it uses a SentencePiece tokenizer the app lacks and is several times the size; an Arabic answer is already caught by its script, and the task is to write English.

## Consequences

- Content: every `keywordChecklist` group in a released level needs a meaning — 286 groups in A1 (124 unit tasks; the capstones' 34 groups are exempt, their grading never uses signals) and 473 in A2 (132 unit tasks; its capstones' 69 groups are exempt for the same reason). Both were authored on 2026-10-24, A1 with this change and A2 later the same day, and the gate holds every released level at full coverage. `tool/meaning/apply_meanings.py` applies a batch textually, keeping the bundle's hand formatting, and checks the shape.
- The app gains the inference model (~25 MB) beside the embedding model (~23 MB) until A2 is covered, then the embedding model and the model answers' role as a signal can go; the model answers stay as what the learner is shown after a miss (ADR 0009).
- The model files cannot be fetched from the development environment (Hugging Face is unreachable there); `tool/meaning/fetch_nli_model.sh` fetches them from any other machine and the owner commits them. Until then the app runs exactly as before this ADR: the entailment model reports itself unavailable and the similarity signal grades.
- `activity_attempts.criteriaScores` gains `parts` (the per-group entailment probabilities) and carries the templated explanation in both languages (`docs/DATA_MODEL.md`).
- `docs/TECH_STACK.md` records the model and that `flutter_onnxruntime` now runs two; `docs/SECURITY.md` is unchanged in substance (nothing new leaves the device, no download); `docs/UX_PRINCIPLES.md`'s Explanations section is rewritten for templated, bilingual, person-written feedback; `docs/ROADMAP.md`'s item 12 is replaced by the grammar model; `docs/LEVEL_STANDARD.md` gains the meanings clause.
- The l10n key for "Generated on your phone" is removed; the Settings row that promised an explaining download is reworded to the grammar check it will become.
- Deterministic and gateable, as ADR 0013 required: the same answer and the same model file give the same probabilities. What the gate cannot do under `flutter test` is run the model; a statement's quality is checked on the phone with the spike and, once the model is in the repository, with a Python mirror over the model answers (every model answer should entail every statement of its task).
- Not yet verified: the model files in the repository, a first run of the app with them on a phone, the iPhone. The spike's numbers are from one Android flagship.
