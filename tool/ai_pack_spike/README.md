# Mohingo AI-pack device spike

A throwaway Flutter app that answers the question [ADR 0013](../../docs/adr/0013-on-device-ai-for-free-answers.md) left to a device test: **can a small language model judge a learner's free answer on the phones Mohingo's learners own, and how well?** Nothing here ships in Mohingo; the spike decides what Phase B (the downloadable AI pack) is built on.

It is a separate Flutter package so that its native inference runtime never touches the app. The root `analysis_options.yaml` excludes it, and its own workflow (`.github/workflows/ai-pack-spike.yml`) formats, analyzes, tests and builds it.

## What it measures

For one candidate model at a time, on the phone:

| Number | How | Bar (ADR 0013) |
|---|---|---|
| Memory | `/proc/meminfo` for the phone, the app's resident set before load, after load and after every judgement | fits the reference phone (iPhone 11/12, 4 GB) with room for the app |
| Speed | wall-clock time of each judgement as the app would wait for it, plus llama.cpp's token counts and timings | median of a few seconds; 5 s is the line the report draws |
| Judgement quality | 22 learner answers with a verdict a teacher would not dispute (`lib/benchmark_cases.dart`): paraphrases, a missing negation, off-topic, an echo of the prompt, Arabic instead of English, broken grammar, wrong tense, the wrong item | how many verdicts and grammar flags are right, and whether the Arabic explanation is Arabic at all |

Every judgement is one structured-JSON call with greedy decoding and a fixed seed (`lib/judge_prompt.dart`), the shape the main app's `LocalJudgementService` will ask for: does the answer do the task, how many grammar issues, a correction, an explanation in English and one in Arabic.

## Candidates

`lib/candidates.dart`: SmolLM2 135M (a pipeline check only), Gemma 3 1B, Llama 3.2 1B, Qwen2.5 1.5B, Qwen3 1.7B (thinking off), and Gemma 3n E2B, which at 3 GB is expected to fail on a 4 GB phone and is there to prove it. All are GGUF files at 4-bit (`Q4_K_M`) from Hugging Face repositories that need no login; a model can also be entered by URL, with a token for a gated repository.

The runtime is [llamadart](https://pub.dev/packages/llamadart) (llama.cpp, CPU only on Android, Metal on iOS). The build hook downloads the native library on the first build; the pubspec limits it to the GGUF runtime and the compact CPU profile.

## Running it

**From CI (no development machine):** Actions → "AI pack spike" → Run workflow → when it finishes, open the run and download the `mohingo-ai-pack-spike-apk` artifact. Unzip, copy the APK to the phone, install it (allow installing from this source). It is a separate app, "Mohingo AI Spike", beside Mohingo.

**Locally:** `cd tool/ai_pack_spike && flutter pub get && flutter run --release` with a phone connected. Measure in release mode only: debug builds are several times slower.

On the phone, on Wi-Fi:

1. Pick **SmolLM2 135M** first, Download → Load → Run. It judges badly, but it proves the pipeline in a minute.
2. Pick a real candidate, Download (0.8-1.1 GB, once; the file stays in the app's cache) → Load → Run. Wait for all 22 answers.
3. **Copy report** and paste it into the conversation. Then **Unload**, and **Delete file** if space is short, before the next candidate. One model at a time: two loaded would not fit.

If the app closes during Load or Run, the model did not fit: that is a result too, and the log line before the close is in the report of the previous run.

## Checks

```
cd tool/ai_pack_spike
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test        # the pure parts: cases, prompt, report; no model is loaded
```

iOS: the deployment target is 16.4, llamadart's floor. An iPhone build (`flutter build ios --release --no-codesign` in CI) proves it compiles; installing on an iPhone needs an Apple developer account and a Mac, as for Mohingo itself.
