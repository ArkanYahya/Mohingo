# 2026-10-24 — the NLI engine (MobileBERT-MNLI, DistilBERT-MNLI) and Qwen2.5 1.5B on a Galaxy S24 Ultra

Spike build `cc71452` (v5: the NLI engine; LLM prompt v4 without the model answer; Run only for the loaded model). Three reports pasted by the owner.

## Reading

| | MobileBERT-MNLI (NLI) | DistilBERT-MNLI (NLI) | Qwen2.5 1.5B (LLM, prompt v4, Fast) |
|---|---|---|---|
| Download | 25 MB | 67 MB | 1.1 GB |
| Memory after load / peak | 301 / 320 MB | 373 / 387 MB | 2210 / 2358 MB |
| Time per answer (median) | **28 ms** (12 ms a part) | 22 ms | 7.5 s (prompt 0.4 s, generation 4.1 s, JSON-grammar sampling 3.9 s) |
| Verdicts right | **17/22**, first try, naive hypotheses | 14/22 | 15/22, the best LLM so far |
| Grammar | not asked (a separate model's job) | — | 0 mistakes on all 22, "I like swim … grammatically correct" |

**MobileBERT read the answers.** The discriminations three language models missed, it made: "I like tennis too" against *one thing they do not like* → entailment 0.04, contradiction 0.65; "I can't stand tennis" → 0.95; the weather → neutral 0.92; "Go away." → contradiction 0.73; "Hello! My name is Omar." → job 0.10; "Every weekend I go to the beach" against *last weekend* → contradiction 0.78; the shirt against *shoes* → contradiction 0.99; the echoed prompt caught by the sentence count. Four of its five misses are hypothesis wording, not model: *"thanks someone politely"* for "I appreciate it." (lexical); *"…about the friend's volunteering"* when the reply never names the volunteering (the hypothesis asked about the task's situation, not the answer's content); *"…one thing they do not like at work"* for "I can't stand long meetings." (same: *at work* is the task's context); *"describes their morning routine"* against three plain sentences (a category label). Hypotheses v2 state only what the answer itself says. The one real weakness: the country part at 0.61 for an answer with no country (a false positive the verdict survived).

**DistilBERT** was worse and more extreme: "I can't stand tennis" → contradiction 1.00, "I come from Iraq" → *which country* 0.06. Not a candidate.

**Qwen2.5 1.5B** was the best language model of the four tried — real negatives with correct reasons ("did not mention where they are from or their job"), the Arabic answer's parts all true but the code verdict false — and still said yes to "Yes.", to the echoed prompt, to "Every weekend", to the shirt ("asks for the price of the shoes", a hallucination), to the vague email; found no grammar mistake in 22 answers; and needed 2.2 GB and 7.5 s, half of it the JSON grammar over Qwen's 150k-token vocabulary (~40 ms a token). The prompt cache worked for it (prompt 0.4 s), unlike LFM2.

What this decides, as a recommendation to the owner: Phase B's judgement of *meaning* should be a natural-language-inference cross-encoder per rubric part, not a generative model — 250× faster, 7× smaller, more right, and small enough (25 MB) to bundle rather than download. Grammar needs its own small model, since no language model at phone size found a single mistake. Explanations would be templated from the two models' output, in both languages written by a person, which also meets the bilingual rule. The language-model pack stays recorded as tried and not chosen at this size.

## Raw reports (as pasted, tables only; the per-case detail is in the owner's paste of 2026-10-24)

```
# NLI — MobileBERT uncased MNLI (int8) — Xenova/mobilebert-uncased-mnli
labels: entailment/neutral/contradiction; inputs: input_ids,attention_mask,token_type_ids
load: 768 ms, rss before 232 MB -> after 301 MB, peak during run 320 MB
verdicts: 22/22 completed, right 17/22
speed: median 28 ms per answer (all parts), max 49 ms, median 12 ms per part

id | expected | got | ms | parts (entailment p) | tests
likes-synonym | yes | yes ok | 49 | T(0.82) T(0.95) | a dislike said with words the keyword list lacks
likes-other-topic | yes | yes ok | 28 | T(0.98) T(0.98) | a good answer on a different topic from the model answer
likes-no-dislike | no | no ok | 23 | T(0.89) F(0.04) | the dislike is missing (negation)
likes-off-topic | no | no ok | 25 | F(0.07) F(0.07) | off topic
likes-broken-grammar | yes | yes ok | 25 | T(0.92) T(0.97) | right content, several grammar errors
polite-appreciate | yes | no X | 17 | F(0.23) | a polite reply the accepted list does not contain (a real case)
polite-rude | no | no ok | 14 | F(0.06) | grammatical but not polite
intro-complete | yes | yes ok | 36 | T(0.91) T(0.90) T(0.64) | all three parts, different wording
intro-one-part | no | no ok | 38 | T(0.98) T(0.61) F(0.10) | two of three parts missing
intro-broken-grammar | yes | yes ok | 35 | T(0.85) T(0.96) T(0.62) | all parts present, missing verbs and articles
intro-arabic | no | no ok | 32 | T(0.94) F(0.42) F(0.24) | a complete answer, but in Arabic
email-two-of-three | no | no ok | 44 | F(0.18) T(0.84) T(0.69) | interest and a question, but nothing about these days
email-vague | no | no ok | 40 | F(0.04) F(0.08) F(0.08) | polite filler that skips the third part
email-complete | yes | no X | 45 | F(0.07) F(0.41) T(0.58) | all three parts in other words
email-broken-grammar | yes | no X | 44 | F(0.20) F(0.25) T(0.73) | all parts present, several errors
routine-complete | yes | no X | 22 | F(0.06) T(code) | three sentences, none shared with the model answer
routine-yes | no | no ok | 17 | F(0.01) F(code) | a one-word non-answer
routine-echo | no | no ok | 23 | T(0.96) F(code) | the prompt repeated back
weekend-tense | yes | yes ok | 26 | T(0.91) | right content, present tense for a past event
weekend-habit | no | no ok | 21 | F(0.10) | a habit, not what happened last weekend
dislike-register | yes | no X | 23 | F(0.06) | a stronger, informal phrasing (read the explanation for register)
shop-wrong-item | no | no ok | 31 | T(0.83) F(0.00) | the right question about the wrong thing

# NLI — DistilBERT uncased MNLI (int8) — Xenova/distilbert-base-uncased-mnli
load: 132 ms, rss before 266 MB -> after 373 MB, peak during run 387 MB
verdicts: 22/22 completed, right 14/22
speed: median 22 ms per answer (all parts), max 34 ms, median 9 ms per part
(likes-synonym: "one thing they do not like" -> contradiction 1.00; intro-complete: "which country" -> 0.06; every email part 0.00-0.47)

# LLM — Qwen2.5 1.5B Instruct (Q4_K_M), prompt v4, mode fast
load: 2953 ms, rss before 230 MB -> after 2210 MB, peak during run 2358 MB
judgements: 22/22 completed, verdict right 15/22, grammar flag right 18/22, Arabic written 0/22
speed: median 7506 ms, max 15189 ms, 25.3 tokens/s
where the time goes (mean per answer): prompt 368 ms, generation 4077 ms, sampling 3858 ms
wrong: likes-no-dislike yes, email-two-of-three yes, email-vague yes, routine-yes yes, routine-echo yes, weekend-habit yes, shop-wrong-item yes; mistakes 0 on all 22
```
