# Bundled speech audio — pre-generated clips replace runtime device TTS

**Status:** Approved by the product owner on 2026-09-22 after a listening pilot (Kokoro, first four A1 lessons); implementation on `feature/bundled-audio`.
**Date:** 2026-09-22

## Context

Every word the app speaks is a verbatim string from a curriculum bundle: encounter dialogue lines, listening transcripts, partner turns, model texts, key phrases, headwords, examples and grammar forms. The only exception is the Settings "Try it" sample, a Dart literal. No learner-typed or runtime-composed text is ever spoken, and nothing speaks Arabic. Across A1 and A2 that is 3,140 unique strings, ~161k characters, roughly 3.2 hours of speech.

Today `DeviceTextToSpeechService` hands each string to `flutter_tts` at runtime. The result depends entirely on which voice the phone happens to have installed, and on most phones it sounds robotic. Better built-in voices exist on some devices but must be downloaded by the user in system settings, Siri voices are closed to third-party apps, and the quality floor stays low. An online engine at runtime would need an API key in the shipped binary (forbidden by `docs/SECURITY.md`) or a backend (forbidden by ADR 0004), and the keyless "free" endpoints (Google Translate, Edge read-aloud) carry no licence for app use.

Since the text is known at build time, synthesizing it at runtime buys nothing. This design moves synthesis to authoring time.

Pilot findings that shaped the rules below: " / " in grammar forms was read as "slash"; `{name}` slots and "..." produced noise; Arabic place names need a pronunciation lexicon (Kirkuk came out as "KER-kuk"); clips must not end abruptly. All four are handled by the tool's normalisation step. An automated transcription check (faster-whisper over every clip) is part of the tool as an optional verification.

## Decision summary

1. **Every speakable bundle string ships as a pre-generated audio clip** under `assets/audio/en/<LEVEL>/`, one manifest per level. The app plays clips; the device engine remains only as a fallback for text without a clip.
2. **Engine: Kokoro-82M v1.0** (Apache 2.0) run on the authoring machine through `kokoro-onnx`. Free, no account, deterministic, ~20 English voices. The tool's engine is a module boundary so Google Chirp 3 HD can be added later without touching the app.
3. **Format: mono AAC-LC in `.m4a`, 32 kbps, 24 kHz**, encoded with the ffmpeg binary that `imageio-ffmpeg` bundles. Plays natively on Android and iOS through `audioplayers`, already a dependency. Expected size: ~12 MB for A1, ~35 MB for A2.
4. **Distinct voices per character.** Dialogue lines are rendered in a per-speaker voice from a global cast; everything a "teacher" reads (vocabulary, grammar, key phrases, model texts, unlabelled transcripts) uses one teacher voice; partner turns in speaking tasks use one partner voice.
5. **The gate suite enforces it**: a released level must have a manifest whose `contentVersion` matches its bundle, a clip for every speakable string in the role the app will ask for, no orphan files, and a size budget.
6. **Decisions taken for the learner** (owner said "go on" without picking): teacher voice `af_bella` (clearest on "your" in the pilot's transcription check), partner voice `am_michael`, natural speed only with the app's "Slower" button implemented as playback rate, blank slots rendered as a pause so the audio matches the card text.

## Non-goals

- Downloading audio packs on demand (Play Asset Delivery / Background Assets). v1 bundles everything, per ADR 0004; packs are the escape hatch when a later level pushes the app past Play's 200 MB mobile-data threshold. Noted in ROADMAP.
- Per-speaker voices inside *unlabelled* multi-speaker transcripts (A2 writes two-person listening dialogues without "Name:" labels). Those play in the teacher voice. Marking turns is a content-authoring change for a later batch.
- Pre-rendered slow clips, Arabic audio, a voice picker in Settings, and the `ttsSource` media specifications (modelled, never spoken; unchanged).

## Asset layout and manifest

```
assets/audio/en/A1/manifest.json
assets/audio/en/A1/clips/<clipId>.m4a
assets/audio/en/A2/manifest.json
assets/audio/en/A2/clips/<clipId>.m4a
```

`pubspec.yaml` lists the two directories per level (Flutter includes a directory's files, not its subdirectories).

Manifest schema, version 1:

```json
{
  "schemaVersion": 1,
  "levelId": "a1",
  "contentVersion": "A1-COMPLETE-2026.09.22",
  "generatedAt": "2026-09-22T15:04:05Z",
  "engine": { "name": "kokoro-onnx", "model": "kokoro-v1.0", "speed": 1.0 },
  "audio": { "container": "m4a", "codec": "aac", "bitrateKbps": 32, "sampleRateHz": 24000, "channels": 1 },
  "clips": {
    "<textKey>": { "_": "clips/<clipId>.m4a", "Maya": "clips/<clipId>.m4a" }
  }
}
```

- **textKey** = first 16 hex characters of SHA-1 over the UTF-8 bytes of the *normalised* text. Normalisation, identical in Dart and Python and pinned by shared test vectors: Unicode NFC; `’` → `'`; trim; every run of whitespace → one space. The bundle text is keyed *as authored*, placeholders included (`"My name is {name}."`), so both the lesson step and Review find the same clip.
- **role** = `_` (teacher, the default), a dialogue speaker label verbatim (`"Maya"`), or `partner`.
- **clipId** = first 16 hex characters of SHA-1 over the recipe that produced the audio: engine id, voice, speed, rules version, and the spoken segments after normalisation and lexicon. Changing the lexicon or the cast therefore changes the id, so "generate only what is missing" stays correct and `--prune` removes what nothing references.

Clips may be shared across roles when their recipe is identical (two speakers with the same voice saying the same line); the manifest simply points both roles at one file.

## Authoring tool (`tool/audio/`)

Python, run only on the authoring machine. Never part of the app; holds no credentials today and, if a cloud engine is ever added, is where its key lives (`docs/SECURITY.md`).

```
tool/audio/
  README.md                 setup, model download, commands
  requirements.txt          kokoro-onnx, soundfile, numpy, imageio-ffmpeg (faster-whisper optional)
  generate_audio.py         CLI
  cast.json                 teacher, partner, speaker → voice, gender pools, known genders
  lexicon.json              word → IPA overrides (Kirkuk, Basra, …)
  extra_strings.json        non-bundle strings that still need a clip (the Settings sample)
  mohingo_audio/
    speakables.py           the 13 bundle paths → [(text, role)], mirrors the app's call sites
    textkey.py              normalise() and text_key() — the shared rule
    speech.py               segments_for(), lexicon application, recipe hash
    cast.py                 voice_for(role)
    engine_kokoro.py        kokoro-onnx wrapper (float speed input, phoneme override, padding, fade, peak normalise)
    encode.py               wav → m4a via imageio-ffmpeg
    manifest.py             read/write, prune
  tests/                    pytest: textkey vectors, segments, speakables counts, cast determinism
  models/                   gitignored: kokoro model + voices file
```

CLI: `python tool/audio/generate_audio.py --level A1 [--only-missing (default)] [--force] [--prune] [--limit N] [--dry-run] [--check]`. Prints strings found, clips generated/reused, unmapped speakers (assigned deterministically from the gender pools and listed so the cast can be extended), and total size. `--check` runs the faster-whisper comparison and prints every clip whose transcription drifts from its text, for a human to listen to.

**Speakable strings** (must stay in step with the app's call sites; the Dart gate test is the source of truth):

| Bundle path | Role |
|---|---|
| `units[].lessons[].encounter.dialogue[].en` | speaker label |
| `units[].lessons[].activities[].audioTranscript` | `_` (labelled `Name: …` transcripts are rendered per speaker and stored under `_`) |
| `units[].lessons[].activities[].partnerTurns[]` (or A1's legacy `examinerTurns[]`) | `partner` |
| `units[].lessons[].readingText.text` | `_` |
| `chunks[].text`, `lexicon[].headword`, `lexicon[].examples[].en`, `grammar[].form`, `grammar[].examples[].en` | `_` |
| `finalMission.activities[]` and `finalAssessment.sections.*.activities[]` transcripts and turns | as above |
| `extra_strings.json` | `_` |

**Speech normalisation** (what the engine is given): split the text on `{placeholder}`, `...`/`…` and ` / `; drop pieces with no letters; keep a trailing `?`/`!` on the last spoken piece so the question intonation survives; join pieces with 0.45 s of silence. A labelled transcript whose every label is a dialogue speaker of that level is split per speaker and joined with 0.5 s gaps. Words in `lexicon.json` have their phonemes replaced. Every clip gets 0.10 s lead-in, a 30 ms fade-out, 0.25 s tail, and is peak-normalised to −1 dBFS so volume is consistent across voices. Speed 1.0.

**Cast**: `cast.json` maps speaker labels to voices globally, so Omar sounds the same in A1 and A2. Unmapped labels pick a voice from the female or male pool by the label's known gender, else by a stable hash, and the tool lists them.

## App changes

- `TextToSpeechService.speak()` gains an optional `speaker` argument: a content speaker label, or `kPartnerSpeaker`, or null for the teacher voice. `DeviceTextToSpeechService` ignores it.
- `phraseForSpeech` (placeholder → ellipsis) moves from the activity-engine widget file into the speech domain and is applied by the **device** service only. Callers pass the raw bundle text, so clip lookups hit and the Review/Phrase-page bug of speaking literal braces disappears.
- New `AudioClipIndex` (speech domain): built from every catalogue level's manifest; `assetPathFor(text, speaker)` tries the speaker role, then `_`, then any role; `textKey()` is the shared normalisation.
- New `ClipPlayer` interface (speech domain) with `AudioplayersClipPlayer` (data): `play(assetPath, playbackRate)` completes when the clip ends or is stopped, guarded by a length-based timeout like the device service; `stop()`.
- New `BundledAudioTextToSpeechService` (data): looks the text up, plays the clip through `ClipPlayer` and emits `playing`/`stopped` on `playbackState`; on a miss, delegates to the device service with the same arguments. `stop()` stops both.
- Rate: the existing preference is flutter_tts's 0–1 scale with 0.5 = normal. `playbackRateFor(rate)` = `rate / 0.5` clamped to 0.6–1.5. The audio card's "Slower" (×0.6) therefore plays at 0.6×. Pitch is ignored for clips and the pitch slider is removed from Settings (the preference provider stays; nothing else uses it).
- Providers: `audioClipIndexProvider` (keepAlive, async; a missing or unparsable manifest logs and yields an empty index, never a crash), `clipPlayerProvider`, and `textToSpeechServiceProvider` now returns the bundled service wrapping the device one.
- `LevelCatalogEntry` gains `audioManifestAssetPath`; A1 and A2 set it.
- Call sites: the lesson conversation step passes `speaker: line.speaker`; the partner-turns card passes `speaker: kPartnerSpeaker`; the key-phrases step passes the raw phrase; the Settings sample is listed in `extra_strings.json` so it has a clip.

Interfaces stay the seam they already are: tests keep overriding `textToSpeechServiceProvider` with `FakeTextToSpeechService`, which records `speaker` alongside text and rate.

## Gate (test/content/levels)

`LevelGateConfig` gains `audioManifestAssetPath` and `audioBudgetBytes` (60 MB per level). New `level_audio_test.dart`, run over every configured level:

1. The manifest exists, parses, and its `contentVersion` equals the bundle's.
2. For every `Speakable` from `SpeakableStrings.of(bundle)` (new, in `lib/content/audio/`), `clips[textKey][role]` exists, with the role rules above (a labelled transcript needs `_`).
3. Every path the manifest references exists on disk; every `.m4a` in `clips/` is referenced by the manifest.
4. Total clip bytes are within the budget.
5. `level_config_test.dart`: the catalogue's `audioManifestAssetPath` equals the gate's.

`SpeakableStrings` is app code so the tool's `speakables.py` has a Dart counterpart to be checked against; a unit test pins the expected count per level from the census (A1 1,522 unique strings + roles, A2 1,623).

## Testing

- Dart unit tests: textKey vectors (shared with Python), `AudioClipIndex` lookup precedence and tolerance, `BundledAudioTextToSpeechService` (hit → player, miss → fallback, rate mapping, stop, state events), `phraseForSpeech` still applied on the device path, `SpeakableStrings` over a small in-memory bundle and over the real bundles.
- Widget tests: the conversation step passes the speaker; the partner card passes `kPartnerSpeaker`; the key-phrases step passes the raw phrase.
- Gate suite for A1 and A2 with the generated assets.
- Python: pytest for `textkey` vectors, `segments_for`, `speakables` counts, cast determinism.
- Whole-suite: `dart format`, `flutter analyze`, `flutter test` all green.
- Not possible here: playback on a real device. Recorded in README's known limitations like every other device-dependent guarantee.

## Docs to update in the same change

ADR 0008 (this decision), `TECH_STACK.md` (engine, tool, the "no pre-recorded audio" lines), `ARCHITECTURE.md` (speech layer, tool boundary), `DATA_MODEL.md` (manifest schema, the `ttsSource` note), `LEVEL_STANDARD.md` (a level ships its audio; cost per level), `TESTING.md` (gate, tool tests, `--check`), `GLOSSARY.md` (clip, manifest, role, cast, textKey), `CONVENTIONS.md` (`tool/audio/` is Python), `SECURITY.md` (tool credentials rule), `README.md` (setup, size, known limitations), `ROADMAP.md` (audio packs deferred), `CLAUDE.md` (header, commands).
