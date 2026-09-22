# Speech audio authoring tool

Generates the bundled speech clips the app plays instead of the phone's text-to-speech engine. Why: [ADR 0008](../../docs/adr/0008-bundled-pre-generated-speech-audio.md). How it fits: [docs/superpowers/specs/2026-09-22-bundled-audio-design.md](../../docs/superpowers/specs/2026-09-22-bundled-audio-design.md).

This runs only on the authoring machine. Nothing here ships in the app, and no credential lives here today; if a cloud engine is ever added, its key belongs here and nowhere else ([docs/SECURITY.md](../../docs/SECURITY.md)).

## Setup (once)

1. Python 3.11 or newer. Create the virtual environment at a **short path**: Windows without long-path support cannot install `onnxruntime` into a deep folder.
   ```
   python -m venv %LOCALAPPDATA%\Temp\mtts\venv
   %LOCALAPPDATA%\Temp\mtts\venv\Scripts\python -m pip install -r tool/audio/requirements.txt
   ```
2. Download the Kokoro v1.0 model into `tool/audio/models/` (gitignored):
   - `kokoro-v1.0.onnx`: the fp32 `onnx/model.onnx` from https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX (about 310 MB), saved under that name.
   - `voices-v1.0.bin`: from the kokoro-onnx GitHub release `model-files-v1.0` (https://github.com/thewh1teagle/kokoro-onnx/releases), about 27 MB.
3. Optional, for `--check`: `pip install faster-whisper` (downloads a recognizer model on first use).

## Commands (run from the repo root)

```
python tool/audio/generate_audio.py --level A1            # generate what is missing, write the manifest
python tool/audio/generate_audio.py --level A1 --prune    # also delete clips nothing references
python tool/audio/generate_audio.py --level A1 --dry-run  # counts and unmapped speakers only
python tool/audio/generate_audio.py --level A1 --limit 5  # smoke run
python tool/audio/generate_audio.py --level A1 --check    # transcribe new clips and flag drift
python -m pytest tool/audio/tests -q                      # the tool's own tests
```

A full level takes about 0.5 s of compute per second of audio on a laptop CPU: roughly 25 minutes for A1, 70 for A2.

## What it does

`mohingo_audio/speakables.py` lists every bundle string the app speaks and the role it is spoken in (`_` teacher, a dialogue speaker, a speaking task's `partnerSpeaker` for its partner turns, or `partner` for a task that names nobody). It mirrors `lib/content/audio/speakable_strings.dart`; the level gate `test/content/levels/level_audio_test.dart` holds the manifest to the Dart list, so a new call site in the app must be added to both.

For each string the tool chooses a voice from `cast.json`, turns the text into what the engine should say (`speech.py`: `{slots}`, `...` and ` / ` become pauses, a `Name: …` transcript is rendered per speaker), applies `lexicon.json` for names the engine mispronounces, renders with Kokoro, pads and normalises, encodes to mono AAC at 32 kbps, and writes `assets/audio/en/<LEVEL>/manifest.json` keyed by the shared text key (`textkey.py`).

Clip ids are hashes of the recipe (engine, speed, rules version, voice, phonemes). Changing a voice in the cast or a word in the lexicon changes the ids of the affected clips, so the next run regenerates exactly those; `--prune` removes the old files.

## Editing the cast or lexicon

- A new dialogue speaker or `partnerSpeaker` label: add it to `speakers` in `cast.json`, or at least to `genders` so the pool is right. The run prints every label it had to guess. A partner named after a dialogue character (`Anna`) shares that character's voice; a role (`Waiter`, `Receptionist`, `Examiner`) has its own.
- A mispronounced word: add `"Word": "IPA"` to `lexicon.json` using Kokoro's espeak-style IPA (see the existing entries), rerun the level with `--prune`, and listen.
- After any content change to a bundle: rerun the level, then `flutter test test/content/levels`. The gate fails until the manifest's `contentVersion` matches the bundle's and every spoken string has a clip.
