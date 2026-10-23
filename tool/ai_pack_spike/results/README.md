# Spike results

One file per run the owner pasted back, named `<date>-<model id>-<phone>.md`, kept verbatim under a short reading. The reading is what ROADMAP item 12 and ADR 0013 cite; the raw report is the evidence.

| Run | Phone | Model | Memory (rss after load / peak) | Speed (median) | Verdicts right | Reading |
|---|---|---|---|---|---|---|
| [2026-10-23](2026-10-23-gemma-3-1b-galaxy-s24-ultra.md) | Galaxy S24 Ultra, 11 GB, 8 cores | Gemma 3 1B it Q4_K_M, full mode, prompt v1 | 1385 MB / 1662 MB | 14.8 s (20.8 tok/s) | 11/22, all "yes" | Fits in memory, far too slow, and no judgement at all: said yes to every answer, graded every answer 0 errors, opened every explanation with "Good!", and wrote 13 of 22 "Arabic" explanations in Bengali, Chinese or English. Not a candidate as a judge. Led to prompt v2 (checks before verdict, strict, examples), the fast mode, the timing breakdown and the thread setting. |
