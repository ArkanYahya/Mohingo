# 2026-10-23 — Gemma 3 1B it (Q4_K_M) on a Galaxy S24 Ultra

Spike build `f074c32` (prompt v1: verdict first, "friendly" explanation, full JSON with correction and Arabic). The owner's phone, not the reference phone: 11 GB of RAM and a 2024 flagship CPU, so the memory number transfers to an iPhone 11/12 only as a lower bound and the speed number is optimistic.

## Reading

- **Memory:** 170 MB → 1385 MB after load, 1662 MB peak. A 1B model at 4-bit with a 1024-token context costs about 1.5 GB resident. On a 4 GB phone that is tight beside the app itself but not hopeless; a 1.5B model would add ~0.5 GB.
- **Speed:** median 14.8 s, max 20.7 s per answer, 20.8 generated tokens/s. The bar is a few seconds. Generation of ~90-125 tokens accounts for ~5 s; the rest is unexplained in this report, which is why v2 reports llama.cpp's sampling time (a JSON-schema grammar makes every token's sampling expensive) and lets the thread count be changed.
- **Judgement:** none. `answers_task` was true for all 22 answers, including "The weather is nice today.", "Go away.", "Yes.", the prompt echoed back and an answer in Arabic. `grammar_issues` was 0 for all 22, including "I like swim and I love read books. I no like run." Every explanation began "Good!" (one began "The answer is clear"). The model also hallucinated: for the off-topic answer it wrote "You said two things you like and one thing you don't like", and for "Go away." it praised a polite reply. The corrections were often the model answer copied, not the learner's answer fixed.
- **Arabic:** 9 of 22 explanations contained Arabic letters, but several were mixed; the rest were Bengali (8), Chinese (4) or English. Of the Arabic ones, "لا أستطيع أن آكل الحليب" and "أتنتمي إلى العراق" show the level.

What this decides: Gemma 3 1B is not a judge at this size with this prompt, and the "friendly" instruction plus verdict-first JSON order invited the sycophancy. Prompt v2 puts the checks (`is_english`, `missing`) before the verdict, says "strict", and gives one failing example; a fast mode drops the correction and the Arabic to measure the verdict's cost alone. Qwen2.5-1.5B and Llama 3.2 1B are next, on v2.

## Raw report (as pasted)

```
# Mohingo AI-pack spike report
device: android CP2A.260605.016.S928BXXU6EZIF; RAM total 11085 MB, available 3246 MB; app rss 130 MB; 8 cores
model: Gemma 3 1B it (Q4_K_M) — hf://unsloth/gemma-3-1b-it-GGUF/gemma-3-1b-it-Q4_K_M.gguf
runtime: CPU / LlamaRuntime.llamaCpp / llamadart 0.16
load: 2411 ms, rss before 170 MB -> after 1385 MB, peak during run 1662 MB
judgements: 22/22 completed, verdict right 11/22, grammar flag right 18/22, Arabic written 9/22
speed: median 14774 ms, max 20676 ms, 20.8 tokens/s (too slow or incomplete)

id | expected | got | issues | ms | prompt/gen tokens | tests
likes-synonym | yes | yes ok | 0 | 12757 | 293/87 | a dislike said with words the keyword list lacks
likes-other-topic | yes | yes ok | 0 | 9864 | 19/94 | a good answer on a different topic from the model answer
likes-no-dislike | no | yes X | 0 | 12533 | 16/98 | the dislike is missing (negation)
likes-off-topic | no | yes X | 0 | 13465 | 11/97 | off topic
likes-broken-grammar | yes+err | yes ok | 0 | 12648 | 19/90 | right content, several grammar errors
polite-appreciate | yes | yes ok | 0 | 9833 | 32/69 | a polite reply the accepted list does not contain (a real case)
polite-rude | no | yes X | 0 | 11870 | 8/88 | grammatical but not polite
intro-complete | yes | yes ok | 0 | 14774 | 66/98 | all three parts, different wording
intro-one-part | no | yes X | 0 | 15105 | 6/116 | two of three parts missing
intro-broken-grammar | yes+err | yes ok | 0 | 10027 | 17/72 | all parts present, missing verbs and articles
intro-arabic | no | yes X | 0 | 12591 | 19/89 | a complete answer, but in Arabic
email-two-of-three | no | yes X | 0 | 20676 | 144/125 | interest and a question, but nothing about these days
email-vague | no | yes X | 0 | 15442 | 17/107 | polite filler that skips the third part
email-complete | yes | yes ok | 0 | 18494 | 38/123 | all three parts in other words
email-broken-grammar | yes+err | yes ok | 0 | 18844 | 29/127 | all parts present, several errors
routine-complete | yes | yes ok | 0 | 17216 | 65/108 | three sentences, none shared with the model answer
routine-yes | no | yes X | 0 | 15671 | 7/102 | a one-word non-answer
routine-echo | no | yes X | 0 | 18873 | 13/120 | the prompt repeated back
weekend-tense | yes+err | yes ok | 0 | 13744 | 46/84 | right content, present tense for a past event
weekend-habit | no | yes X | 0 | 14652 | 13/92 | a habit, not what happened last weekend
dislike-register | yes | yes ok | 0 | 18793 | 45/89 | a stronger, informal phrasing (read the explanation for register)
shop-wrong-item | no | yes X | 0 | 20288 | 43/74 | the right question about the wrong thing
```

Selected explanations (the rest followed the same pattern):

```
## likes-off-topic
answer: The weather is nice today.
corrected: I like football and I love music. I don’t like tennis.
en: Good! You said two things you like and one thing you don’t like. That’s a good start!
ar: الطقس جميل اليوم. جيد! لقد ذكرت شيئين تحبهما وما شيئاً لا تحبهما.

## polite-rude
answer: Go away.
corrected: Thank you. / Thanks.
en: Good! You used the correct response. It's polite to say 'Thank you' or 'Thanks'.
ar: 谢谢。你使用了正确的回复。这是礼貌的回答。

## likes-broken-grammar
answer: I like swim and I love read books. I no like run.
corrected: I like swim and I love read books. I don't like run.
en: Good! You said two things you like and one thing you don't like. That's a good start!
ar: আমি সাঁতার চাই এবং আমি বই পড়ি। আমি দৌড়াতে পছন্দ করি না।

## intro-arabic
answer: اسمي عمر وأنا من العراق وأعمل مهندساً.
corrected: Name: Omar. I'm from Iraq and I work as a engineer.
en: Good! You used the correct form of 'name' and 'from'.  Try to make it a little more natural sounding.
ar: اسمي عمر وأنا من العراق وأعمل مهندساً.

## weekend-tense
answer: Last weekend I go to the beach with my friends and we swim.
corrected: Last weekend, I went to the beach with my friends and we swam.
en: Good! You used correct grammar and vocabulary. You can add 'really' to make it more enthusiastic.
ar: গত週末, আমি আমার দাদুর সাথে যেতে গিয়েছিলাম এবং আমরা একসাথে রান্না করেছি।
```
