# Bundled Speech Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship every spoken curriculum string as a pre-generated Kokoro audio clip, played by the app instead of the phone's text-to-speech engine, with the device engine kept only as a fallback.

**Architecture:** A Python authoring tool (`tool/audio/`) enumerates the bundle's speakable strings, synthesizes each with Kokoro in a per-role voice, encodes to mono AAC and writes a per-level manifest keyed by a normalised-text hash and a role. In the app a `BundledAudioTextToSpeechService` sits behind the existing `TextToSpeechService` seam, looks clips up in an `AudioClipIndex` built from the manifests and plays them through `audioplayers`, delegating to `DeviceTextToSpeechService` on a miss. A new level gate asserts every speakable string has its clip.

**Tech Stack:** Python 3.11+ (kokoro-onnx, soundfile, numpy, imageio-ffmpeg, pytest); Flutter/Dart (audioplayers 6.8, crypto, Riverpod codegen); flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-22-bundled-audio-design.md`

## Global Constraints

- Text key = first 16 hex chars of SHA-1 over UTF-8 of the normalised text; normalisation = `’`→`'`, whitespace runs → one space, trim. **No Unicode normalisation in either language**; the tool refuses text that is not already NFC.
- Roles: `_` (teacher), a dialogue speaker label verbatim, `partner`.
- Clip format: mono AAC-LC `.m4a`, 32 kbps, 24 kHz. Layout `assets/audio/en/<LEVEL>/manifest.json` + `assets/audio/en/<LEVEL>/clips/<clipId>.m4a`.
- Engine: Kokoro v1.0 via kokoro-onnx, speed 1.0. Teacher voice `af_bella`, partner voice `am_michael`.
- Playback rate = `rate / 0.5` clamped to 0.6–1.5. Pitch ignored for clips.
- Per-level audio budget: 60 MB.
- The app must never crash on a missing or broken manifest; it falls back to the device engine.
- All user-facing copy stays bilingual; this feature adds no new copy.
- Every doc in the spec's "Docs to update" list is updated in this branch, with its Last-verified line bumped to 2026-09-22.
- Commit after every task; `dart format`, `flutter analyze`, `flutter test` green before the final commit.

---

### Task 1: Python tool — text keys and speech segmentation

**Files:**
- Create: `tool/audio/mohingo_audio/__init__.py` (empty)
- Create: `tool/audio/mohingo_audio/textkey.py`
- Create: `tool/audio/mohingo_audio/speech.py`
- Create: `tool/audio/tests/test_textkey.py`, `tool/audio/tests/test_speech.py`, `tool/audio/tests/conftest.py`
- Create: `tool/audio/requirements.txt`

**Interfaces:**
- Produces: `normalise(text) -> str`, `text_key(text) -> str`, `assert_nfc(text)`; `segments_for(text) -> list[str]`, `split_labelled(transcript, known_speakers) -> list[tuple[str,str]] | None`, `RULES_VERSION = 1`.

- [ ] **Step 1: Write the failing tests**

`tool/audio/tests/conftest.py`:
```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
```

`tool/audio/tests/test_textkey.py`:
```python
import pytest
from mohingo_audio.textkey import normalise, text_key, assert_nfc

# Shared with test/features/speech/audio_clip_index_test.dart — change both or neither.
VECTORS = {
    "My name is {name}.": "4a712aa44408d872",
    "  My   name is {name}.\n": "4a712aa44408d872",
    "I\u2019m Omar.": "fe69d774cfd057ee",
    "I'm Omar.": "fe69d774cfd057ee",
    "Good morning.": "5c3e9f7ad0c9c2b8",
    "Hello! I'm Maya. Nice to meet you.": "a29bdc5852db5cbf",
}

def test_vectors():
    for text, key in VECTORS.items():
        assert text_key(text) == key, text

def test_normalise_collapses_whitespace_and_quotes():
    assert normalise("  a \t b\n") == "a b"
    assert normalise("I\u2019m") == "I'm"

def test_refuses_non_nfc():
    with pytest.raises(ValueError):
        assert_nfc("cafe\u0301")  # decomposed é
    assert_nfc("café") is None
```

`tool/audio/tests/test_speech.py`:
```python
from mohingo_audio.speech import segments_for, split_labelled

def test_placeholders_become_pauses_and_keep_question():
    assert segments_for("My name is {name}.") == ["My name is"]
    assert segments_for("I'm {name}.") == ["I'm"]
    assert segments_for("Are you from {country}?") == ["Are you from?"]
    assert segments_for("I live in {place}.") == ["I live in"]

def test_slash_and_ellipsis():
    assert segments_for("my / your") == ["my", "your"]
    assert segments_for("Yes, I am. / No, I'm not.") == ["Yes, I am", "No, I'm not"]
    assert segments_for("What is ...?") == ["What is?"]
    assert segments_for("Where …?") == ["Where?"]

def test_plain_text_untouched():
    assert segments_for("Where do you live?") == ["Where do you live?"]
    assert segments_for("Good morning.") == ["Good morning."]

def test_split_labelled_only_on_known_speakers():
    known = {"Maya", "Omar"}
    assert split_labelled("Maya: Hi. I'm Maya. Omar: I'm Omar.", known) == [("Maya", "Hi. I'm Maya."), ("Omar", "I'm Omar.")]
    assert split_labelled("You are right: we used the wrong sauce.", known) is None
    assert split_labelled("Good morning.", known) is None
    assert split_labelled("Intro. Maya: Hi.", known) is None
```

- [ ] **Step 2: Run to verify they fail**

Run: `python -m pytest tool/audio/tests -q` (with the venv at `C:\Users\arkan.noah\AppData\Local\Temp\mtts\venv`)
Expected: ImportError / ModuleNotFoundError for `mohingo_audio`.

- [ ] **Step 3: Implement**

`tool/audio/mohingo_audio/textkey.py`:
```python
"""The one rule shared with the app (lib/features/speech/domain/audio_clip_index.dart)."""
import hashlib
import re
import unicodedata

_WS = re.compile(r"\s+")


def normalise(text: str) -> str:
    return _WS.sub(" ", text.replace("\u2019", "'")).strip()


def text_key(text: str) -> str:
    return hashlib.sha1(normalise(text).encode("utf-8")).hexdigest()[:16]


def assert_nfc(text: str) -> None:
    """The app cannot normalise Unicode, so authored text must already be NFC."""
    if unicodedata.normalize("NFC", text) != text:
        raise ValueError(f"text is not NFC-normalised: {text!r}")
```

`tool/audio/mohingo_audio/speech.py`:
```python
"""What the engine is actually given for a bundle string."""
import re

RULES_VERSION = 1  # bump when segments_for/split_labelled change: every clip id changes

_SLOT_OR_ELLIPSIS = re.compile(r"\{[^}]+\}|\.\.\.|…")
_LABEL = re.compile(r"(?:^|(?<=\s))([A-Z][A-Za-z']{1,20}):\s")


def segments_for(text: str) -> list[str]:
    """Split on {slots}, ellipses and ' / '; drop letterless pieces; keep a trailing ?/! on the
    last spoken piece so the question intonation survives. Pieces are joined with a pause."""
    text = text.strip()
    parts = re.split(r"\s*/\s*", text) if " / " in text else [text]
    out: list[str] = []
    for p in parts:
        ending = p[-1] if p and p[-1] in "?!" else ""
        spoken = []
        for piece in _SLOT_OR_ELLIPSIS.split(p):
            piece = piece.strip().strip(".?!").strip()
            if re.search(r"[A-Za-z]", piece):
                spoken.append(piece)
        if spoken and ending and not spoken[-1].endswith(ending):
            spoken[-1] += ending
        out.extend(spoken)
    return out or [text]


def split_labelled(transcript: str, known_speakers: set[str]):
    """'Maya: Hi. Omar: Hello.' -> [('Maya','Hi.'),('Omar','Hello.')], only when every label is a
    dialogue speaker of the level and nothing precedes the first label. Otherwise None."""
    parts = _LABEL.split(transcript)
    if len(parts) < 3 or parts[0].strip():
        return None
    segs = []
    for i in range(1, len(parts), 2):
        label, body = parts[i], parts[i + 1].strip()
        if label not in known_speakers or not body:
            return None
        segs.append((label, body))
    return segs
```

`tool/audio/requirements.txt`:
```
kokoro-onnx>=0.4
soundfile>=0.12
numpy>=1.26
imageio-ffmpeg>=0.5
pytest>=8
# optional, for --check:
# faster-whisper>=1.1
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m pytest tool/audio/tests -q`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add tool/audio
git commit -m "tool(audio): text keys and speech segmentation with pinned vectors"
```

---

### Task 2: Python tool — speakable strings and the cast

**Files:**
- Create: `tool/audio/mohingo_audio/speakables.py`, `tool/audio/mohingo_audio/cast.py`
- Create: `tool/audio/cast.json`, `tool/audio/lexicon.json`, `tool/audio/extra_strings.json`
- Create: `tool/audio/tests/test_speakables.py`, `tool/audio/tests/test_cast.py`

**Interfaces:**
- Produces: `Speakable(text, role, source)`, `TEACHER = "_"`, `PARTNER = "partner"`, `speakables_of(bundle: dict) -> list[Speakable]`, `known_speakers(bundle) -> set[str]`; `Cast.load(path) -> Cast`, `Cast.voice_for(role) -> str`, `Cast.unmapped -> set[str]`.

- [ ] **Step 1: Write the failing tests**

`tool/audio/tests/test_speakables.py`:
```python
import json
from pathlib import Path
from mohingo_audio.speakables import speakables_of, known_speakers, TEACHER, PARTNER
from mohingo_audio.textkey import text_key

ROOT = Path(__file__).resolve().parents[3]

def _bundle(level):
    return json.load(open(ROOT / f"assets/content/en/{level}/{level.lower()}-course-bundle.json", encoding="utf-8"))

def test_roles_from_a_tiny_bundle():
    b = {
        "units": [{"lessons": [{"id": "L1",
            "encounter": {"dialogue": [{"speaker": "Maya", "en": "Hi.", "ar": ""}]},
            "readingText": {"title": "t", "text": "A text."},
            "activities": [
                {"id": "A1", "audioTranscript": "Listen."},
                {"id": "A2", "partnerTurns": ["Turn one.", ""]},
                {"id": "A3", "examinerTurns": ["Old turn."]},
                {"id": "A4", "audioTranscript": ""}]}]}],
        "chunks": [{"text": "My name is {name}."}],
        "lexicon": [{"headword": "name", "examples": ["My name is Omar.", {"en": "Name?", "ar": ""}]}],
        "grammar": [{"form": "I am", "examples": [{"en": "I'm Omar.", "ar": ""}]}],
        "finalMission": {"activities": [{"id": "M1", "audioTranscript": "Mission."}]},
        "finalAssessment": {"sections": {"listening": {"activities": [{"id": "S1", "partnerTurns": ["Assess."]}]}}},
    }
    got = {(s.text, s.role) for s in speakables_of(b)}
    assert got == {("Hi.", "Maya"), ("A text.", TEACHER), ("Listen.", TEACHER), ("Turn one.", PARTNER),
                   ("Old turn.", PARTNER), ("My name is {name}.", TEACHER), ("name", TEACHER),
                   ("My name is Omar.", TEACHER), ("Name?", TEACHER), ("I am", TEACHER), ("I'm Omar.", TEACHER),
                   ("Mission.", TEACHER), ("Assess.", PARTNER)}
    assert known_speakers(b) == {"Maya"}

def test_real_bundles_have_the_census_counts():
    # Pinned from the 2026-09-22 census; the Dart gate pins the same numbers.
    a1 = speakables_of(_bundle("A1"))
    a2 = speakables_of(_bundle("A2"))
    assert len({(text_key(s.text), s.role) for s in a1}) == 1533
    assert len({(text_key(s.text), s.role) for s in a2}) == 1623
```
(The A1 number is 1522 unique texts plus the same text spoken by different speakers or roles; confirm the exact figure when the test first runs and pin it, together with the Dart gate's constant in Task 8.)

`tool/audio/tests/test_cast.py`:
```python
from mohingo_audio.cast import Cast

def test_cast_is_deterministic_and_reports_unmapped(tmp_path):
    p = tmp_path / "cast.json"
    p.write_text('{"teacher":"af_bella","partner":"am_michael","speakers":{"Maya":"af_heart"},'
                 '"female":["af_heart","af_sarah"],"male":["am_michael","am_fenrir"],"genders":{"Rania":"f","Faris":"m"}}')
    c = Cast.load(p)
    assert c.voice_for("_") == "af_bella"
    assert c.voice_for("partner") == "am_michael"
    assert c.voice_for("Maya") == "af_heart"
    assert c.voice_for("Rania") in {"af_heart", "af_sarah"}
    assert c.voice_for("Faris") in {"am_michael", "am_fenrir"}
    assert c.voice_for("Zork") == c.voice_for("Zork")
    assert c.unmapped == {"Rania", "Faris", "Zork"}
```

- [ ] **Step 2: Run to verify they fail**

Run: `python -m pytest tool/audio/tests -q` — Expected: ModuleNotFoundError for `speakables` / `cast`.

- [ ] **Step 3: Implement**

`tool/audio/mohingo_audio/speakables.py`:
```python
"""Every string the app hands to TextToSpeechService.speak(), and the role it asks for.
Mirrors lib/content/audio/speakable_strings.dart; the Dart gate is the source of truth."""
from dataclasses import dataclass

TEACHER = "_"
PARTNER = "partner"


@dataclass(frozen=True)
class Speakable:
    text: str
    role: str
    source: str


def _clean(value) -> str | None:
    return value.strip() if isinstance(value, str) and value.strip() else None


def _activity(a: dict, where: str, out: list) -> None:
    t = _clean(a.get("audioTranscript"))
    if t:
        out.append(Speakable(t, TEACHER, f"{where}/{a.get('id')}.audioTranscript"))
    turns = a.get("partnerTurns")
    if turns is None:
        turns = a.get("examinerTurns")
    for i, turn in enumerate(turns or []):
        t = _clean(turn)
        if t:
            out.append(Speakable(t, PARTNER, f"{where}/{a.get('id')}.partnerTurns[{i}]"))


def _example_en(ex) -> str | None:
    return _clean(ex if isinstance(ex, str) else (ex or {}).get("en"))


def speakables_of(bundle: dict) -> list[Speakable]:
    out: list[Speakable] = []
    for u in bundle.get("units", []):
        for l in u.get("lessons", []):
            for i, line in enumerate((l.get("encounter") or {}).get("dialogue", [])):
                t = _clean(line.get("en"))
                if t:
                    out.append(Speakable(t, line["speaker"], f"{l['id']} dialogue[{i}]"))
            rt = l.get("readingText") or {}
            t = _clean(rt.get("text"))
            if t:
                out.append(Speakable(t, TEACHER, f"{l['id']} readingText"))
            for a in l.get("activities", []):
                _activity(a, l["id"], out)
    for c in bundle.get("chunks", []):
        t = _clean(c.get("text"))
        if t:
            out.append(Speakable(t, TEACHER, f"chunk {c.get('id')}"))
    for x in bundle.get("lexicon", []):
        t = _clean(x.get("headword"))
        if t:
            out.append(Speakable(t, TEACHER, f"lexicon {x.get('id')}"))
        for i, ex in enumerate(x.get("examples", [])):
            t = _example_en(ex)
            if t:
                out.append(Speakable(t, TEACHER, f"lexicon {x.get('id')} example[{i}]"))
    for g in bundle.get("grammar", []):
        t = _clean(g.get("form"))
        if t:
            out.append(Speakable(t, TEACHER, f"grammar {g.get('id')}"))
        for i, ex in enumerate(g.get("examples", [])):
            t = _example_en(ex)
            if t:
                out.append(Speakable(t, TEACHER, f"grammar {g.get('id')} example[{i}]"))
    for a in (bundle.get("finalMission") or {}).get("activities", []):
        _activity(a, "finalMission", out)
    for name, sec in ((bundle.get("finalAssessment") or {}).get("sections") or {}).items():
        for a in sec.get("activities", []):
            _activity(a, f"finalAssessment.{name}", out)
    return out


def known_speakers(bundle: dict) -> set[str]:
    return {line["speaker"] for u in bundle.get("units", []) for l in u.get("lessons", [])
            for line in (l.get("encounter") or {}).get("dialogue", []) if line.get("speaker")}
```

`tool/audio/mohingo_audio/cast.py`:
```python
"""Which voice reads which role. Global, so a character sounds the same in every level."""
import hashlib
import json
from pathlib import Path

from .speakables import PARTNER, TEACHER


class Cast:
    def __init__(self, data: dict):
        self.teacher = data["teacher"]
        self.partner = data["partner"]
        self.speakers: dict[str, str] = data.get("speakers", {})
        self.female: list[str] = data["female"]
        self.male: list[str] = data["male"]
        self.genders: dict[str, str] = data.get("genders", {})
        self.unmapped: set[str] = set()

    @classmethod
    def load(cls, path) -> "Cast":
        return cls(json.load(open(path, encoding="utf-8")))

    def voice_for(self, role: str) -> str:
        if role == TEACHER:
            return self.teacher
        if role == PARTNER:
            return self.partner
        if role in self.speakers:
            return self.speakers[role]
        self.unmapped.add(role)
        h = int(hashlib.sha1(role.encode("utf-8")).hexdigest(), 16)
        gender = self.genders.get(role) or ("f" if h % 2 == 0 else "m")
        pool = self.female if gender == "f" else self.male
        return pool[h % len(pool)]
```

`tool/audio/cast.json` — teacher `af_bella`, partner `am_michael`, `speakers` for the A1 named cast (Maya af_heart, Sara af_aoede, Anna af_sarah, Lina af_kore, Noor af_kore, Huda af_sarah, Omar am_michael, Ali am_fenrir, Daniel am_puck, A af_heart, B am_fenrir), pools `female: [af_heart, af_sarah, af_aoede, af_kore]`, `male: [am_michael, am_fenrir, am_puck]`, and `genders` for every A2 name from the census (Rania f, Basma f, Faris m, Yousef m, Karim m, Suha f, Ruba f, Nadia f, Salma f, Ghada f, Iman f, Sawsan f, Maha f, Dina f, Adel m, Tamer m, Sami m, Ghassan m, Layla f, Bashar m, Hind f, Dalia f, Ziad m, Hanan f, Kamal m, Fouad m, Widad f, Zaid m, Kareem m, Maher m, Idris m, Yaser m, Nizar m, Salwa f, Rawan f, Maysoon f, Basel m, Samah f, Tariq m, Hiba f, Basil m, Fadi m, Hazim m, Amal f, Dima f, Sameer m, Nour f, Ammar m, Maryam f, Ilham f, "Mr Jabbar" m, Tareq m, Hadeel f, Muna f, Hisham m, Bilal m, Yusuf m, Adnan m, Jamal m, Munir m, Rana f, Hala f, Ruqayya f, Marwan m, Nawal f, Dalal f, Salim m, Hoda f, Samer m, Suad f, Hani m, Bashir m, Tarek m, Nabil m, Tawfiq m, Bushra f, Rashid m, Jalal m, Amjad m, Samir m, Rami m). Role labels (Customer, Waiter, Nurse, …) are left to the hash and reported.

`tool/audio/lexicon.json`:
```json
{
  "_comment": "word -> Kokoro/espeak IPA. Applied to the phoneme string of the word as Kokoro would say it in isolation.",
  "Kirkuk": "kɪɹkˈuːk",
  "Basra": "bˈʌsɹə",
  "Mosul": "mˈoʊsəl",
  "Erbil": "ˈɛɹbɪl",
  "Najaf": "nˈædʒæf",
  "Karbala": "kˈɑːɹbələ"
}
```

`tool/audio/extra_strings.json`:
```json
["Hello! I'm Maya. Nice to meet you."]
```

- [ ] **Step 4: Run tests, pin the A1 count, verify pass**

Run: `python -m pytest tool/audio/tests -q`. If the A1 count differs from 1533, replace it with the printed value (it is the number of distinct (textKey, role) pairs) and use the same value in Task 8.

- [ ] **Step 5: Commit** — `git add tool/audio && git commit -m "tool(audio): speakable strings, cast, lexicon"`

---

### Task 3: Python tool — engine, encoder, manifest, CLI

**Files:**
- Create: `tool/audio/mohingo_audio/engine_kokoro.py`, `encode.py`, `manifest.py`
- Create: `tool/audio/generate_audio.py`, `tool/audio/README.md`
- Modify: `.gitignore` (add `/tool/audio/models/`)

**Interfaces:**
- Produces: `KokoroEngine(model, voices, lexicon)` with `.id`, `.phonemes(text) -> str`, `.render(parts: list[tuple[str voice, list[str] phonemes]]) -> np.ndarray`; `to_m4a(wav, m4a)`; `Manifest` helpers; CLI `generate_audio.py --level A1 [--force] [--prune] [--limit N] [--dry-run] [--check] [--models DIR]`.

- [ ] **Step 1: Implement the engine**

`tool/audio/mohingo_audio/engine_kokoro.py`:
```python
"""kokoro-onnx wrapper. The onnx-community model wants float `speed` and gives a [1, N]
waveform; kokoro-onnx feeds int32 and expects flat, so _create_audio is replaced."""
import types
import numpy as np

SR = 24000
PAUSE, TURN_GAP = 0.45, 0.5
LEAD, TAIL, FADE = 0.10, 0.25, 0.03
PEAK = 10 ** (-1 / 20)  # -1 dBFS


def silence(seconds: float) -> np.ndarray:
    return np.zeros(int(SR * seconds), dtype=np.float32)


def _create_audio(k, phonemes, voice, speed):
    import kokoro_onnx as ko
    phonemes = phonemes[: ko.MAX_PHONEME_LENGTH]
    tokens = np.array(k.tokenizer.tokenize(phonemes), dtype=np.int64)
    style = np.asarray(voice[len(tokens)], dtype=np.float32).reshape(1, -1)
    ids = np.array([[0, *tokens, 0]], dtype=np.int64)
    audio = k.sess.run(None, {"input_ids": ids, "style": style, "speed": np.array([speed], dtype=np.float32)})[0]
    return np.asarray(audio, dtype=np.float32).reshape(-1), SR


class KokoroEngine:
    id = "kokoro-onnx/kokoro-v1.0"

    def __init__(self, model_path, voices_path, lexicon: dict[str, str], speed: float = 1.0):
        from kokoro_onnx import Kokoro
        self.k = Kokoro(str(model_path), str(voices_path))
        self.k._create_audio = types.MethodType(_create_audio, self.k)
        self.speed = speed
        self._lex = {w: (self.k.tokenizer.phonemize(w, "en-us"), ipa) for w, ipa in lexicon.items() if not w.startswith("_")}

    def phonemes(self, text: str) -> str:
        ph = self.k.tokenizer.phonemize(text, "en-us")
        for word, (bad, good) in self._lex.items():
            if word.lower() in text.lower() and bad in ph:
                ph = ph.replace(bad, good)
        return ph

    def _synth(self, phonemes: str, voice: str) -> np.ndarray:
        samples, sr = self.k.create(phonemes, voice=voice, speed=self.speed, lang="en-us", is_phonemes=True)
        assert sr == SR
        return np.asarray(samples, dtype=np.float32)

    def render(self, parts: list[tuple[str, list[str]]]) -> np.ndarray:
        """parts: [(voice, [phoneme segment, ...]), ...] — segments are joined with PAUSE,
        parts (speaker turns) with TURN_GAP; then lead-in, fade-out, tail, peak-normalise."""
        pieces: list[np.ndarray] = []
        for pi, (voice, segments) in enumerate(parts):
            if pi:
                pieces.append(silence(TURN_GAP))
            for si, seg in enumerate(segments):
                if si:
                    pieces.append(silence(PAUSE))
                pieces.append(self._synth(seg, voice))
        audio = np.concatenate(pieces)
        n = min(int(SR * FADE), len(audio))
        if n:
            audio[-n:] *= np.linspace(1.0, 0.0, n, dtype=np.float32)
        peak = float(np.max(np.abs(audio))) if len(audio) else 0.0
        if peak > 0:
            audio *= PEAK / peak
        return np.concatenate([silence(LEAD), audio, silence(TAIL)])
```

`tool/audio/mohingo_audio/encode.py`:
```python
import subprocess
import imageio_ffmpeg

def to_m4a(wav_path, m4a_path, bitrate="32k") -> None:
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", str(wav_path),
                    "-ac", "1", "-c:a", "aac", "-b:a", bitrate, str(m4a_path)], check=True)
```

`tool/audio/mohingo_audio/manifest.py`:
```python
import json
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1

def load(path: Path) -> dict | None:
    return json.load(open(path, encoding="utf-8")) if path.exists() else None

def build(level_id: str, content_version: str, engine_id: str, speed: float, clips: dict[str, dict[str, str]]) -> dict:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "levelId": level_id,
        "contentVersion": content_version,
        "generatedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "engine": {"name": engine_id, "speed": speed},
        "audio": {"container": "m4a", "codec": "aac", "bitrateKbps": 32, "sampleRateHz": 24000, "channels": 1},
        "clips": {k: dict(sorted(v.items())) for k, v in sorted(clips.items())},
    }

def write(path: Path, manifest: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
        f.write("\n")

def referenced_files(manifest: dict) -> set[str]:
    return {p for roles in manifest["clips"].values() for p in roles.values()}
```

- [ ] **Step 2: Implement the CLI**

`tool/audio/generate_audio.py`:
```python
"""Generate the bundled speech clips for one level.

  python tool/audio/generate_audio.py --level A1            # only what is missing
  python tool/audio/generate_audio.py --level A1 --prune    # also delete unreferenced clips
  python tool/audio/generate_audio.py --level A1 --dry-run  # plan only, no engine loaded
  python tool/audio/generate_audio.py --level A1 --check    # transcribe new clips (needs faster-whisper)

Run from the repo root. Models go in tool/audio/models/ (see README.md).
"""
import argparse
import hashlib
import json
import sys
import time
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from mohingo_audio.cast import Cast                                   # noqa: E402
from mohingo_audio.speakables import PARTNER, TEACHER, Speakable, known_speakers, speakables_of  # noqa: E402
from mohingo_audio.speech import RULES_VERSION, segments_for, split_labelled  # noqa: E402
from mohingo_audio.textkey import assert_nfc, text_key                  # noqa: E402
from mohingo_audio import manifest as mf                                # noqa: E402

ROOT = HERE.parents[1]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--level", required=True, help="A1, A2, ...")
    ap.add_argument("--force", action="store_true", help="regenerate every clip")
    ap.add_argument("--prune", action="store_true", help="delete clips the manifest no longer references")
    ap.add_argument("--limit", type=int, default=0, help="stop after N new clips (smoke runs)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--check", action="store_true", help="transcribe new clips with faster-whisper and report drift")
    ap.add_argument("--models", default=str(HERE / "models"))
    ap.add_argument("--speed", type=float, default=1.0)
    a = ap.parse_args()

    level = a.level.upper()
    bundle_path = ROOT / "assets/content/en" / level / f"{level.lower()}-course-bundle.json"
    audio_dir = ROOT / "assets/audio/en" / level
    clips_dir = audio_dir / "clips"
    cache_dir = ROOT / "build/audio-cache" / level
    bundle = json.load(open(bundle_path, encoding="utf-8"))
    cast = Cast.load(HERE / "cast.json")
    lexicon = json.load(open(HERE / "lexicon.json", encoding="utf-8"))
    extras = json.load(open(HERE / "extra_strings.json", encoding="utf-8"))

    speakables = speakables_of(bundle) + [Speakable(t, TEACHER, "extra_strings.json") for t in extras]
    speakers = known_speakers(bundle)
    for s in speakables:
        assert_nfc(s.text)

    engine = None
    def get_engine():
        nonlocal engine
        if engine is None:
            from mohingo_audio.engine_kokoro import KokoroEngine
            engine = KokoroEngine(Path(a.models) / "kokoro-v1.0.onnx", Path(a.models) / "voices-v1.0.bin", lexicon, a.speed)
        return engine

    engine_id = "kokoro-onnx/kokoro-v1.0"
    lex_hash = hashlib.sha1(json.dumps(lexicon, sort_keys=True).encode()).hexdigest()[:8]

    # 1. Plan: (textKey, role) -> parts, and the recipe that names the clip.
    clips: dict[str, dict[str, str]] = {}
    jobs: dict[str, list[tuple[str, list[str]]]] = {}   # clipId -> parts (voice, phoneme segments)
    texts_by_key: dict[str, str] = {}
    for s in speakables:
        key = text_key(s.text)
        texts_by_key[key] = s.text
        if s.role in clips.get(key, {}):
            continue
        labelled = split_labelled(s.text, speakers) if s.role == TEACHER else None
        if labelled:
            parts_text = [(cast.voice_for(sp), segments_for(body)) for sp, body in labelled]
        else:
            parts_text = [(cast.voice_for(s.role), segments_for(s.text))]
        if a.dry_run:
            recipe_src = json.dumps([engine_id, a.speed, RULES_VERSION, lex_hash, parts_text])
            parts = parts_text
        else:
            parts = [(v, [get_engine().phonemes(seg) for seg in segs]) for v, segs in parts_text]
            recipe_src = json.dumps([engine_id, a.speed, RULES_VERSION, parts])
        clip_id = hashlib.sha1(recipe_src.encode("utf-8")).hexdigest()[:16]
        clips.setdefault(key, {})[s.role] = f"clips/{clip_id}.m4a"
        jobs[clip_id] = parts

    wanted = {f"clips/{cid}.m4a" for cid in jobs}
    todo = [cid for cid in jobs if a.force or not (clips_dir / f"{cid}.m4a").exists()]
    print(f"{level}: {len(speakables)} speakable strings, {len(clips)} distinct texts, "
          f"{len(jobs)} clips wanted, {len(todo)} to generate, {len(jobs) - len(todo)} reused")
    if cast.unmapped:
        print("speakers not in cast.json (voice chosen by gender/hash):", ", ".join(sorted(cast.unmapped)))
    if a.dry_run:
        return 0

    # 2. Generate.
    import soundfile as sf
    from mohingo_audio.encode import to_m4a
    clips_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)
    made, t0, seconds = [], time.perf_counter(), 0.0
    for i, cid in enumerate(todo, 1):
        if a.limit and len(made) >= a.limit:
            break
        audio = get_engine().render(jobs[cid])
        seconds += len(audio) / 24000
        wav = cache_dir / f"{cid}.wav"
        sf.write(str(wav), audio, 24000, subtype="PCM_16")
        to_m4a(wav, clips_dir / f"{cid}.m4a")
        made.append(cid)
        if i % 50 == 0 or i == len(todo):
            print(f"  {i}/{len(todo)}  {time.perf_counter() - t0:.0f}s elapsed, {seconds:.0f}s of audio")

    # 3. Manifest (only clips that exist on disk are recorded).
    present = {k: {r: p for r, p in roles.items() if (audio_dir / p).exists()} for k, roles in clips.items()}
    present = {k: v for k, v in present.items() if v}
    mf.write(audio_dir / "manifest.json", mf.build(level.lower(), bundle["contentVersion"], engine_id, a.speed, present))

    # 4. Orphans.
    on_disk = {f"clips/{p.name}" for p in clips_dir.glob("*.m4a")}
    orphans = on_disk - wanted
    if orphans and a.prune:
        for rel in orphans:
            (audio_dir / rel).unlink()
        print(f"pruned {len(orphans)} unreferenced clips")
    elif orphans:
        print(f"{len(orphans)} unreferenced clips on disk; rerun with --prune to delete them")

    total = sum((audio_dir / p).stat().st_size for roles in present.values() for p in roles.values())
    print(f"manifest: {sum(len(v) for v in present.values())} clip references, {total / 1e6:.1f} MB on disk")
    missing = len(jobs) - len({cid for cid in jobs if (clips_dir / f'{cid}.m4a').exists()})
    if missing:
        print(f"WARNING: {missing} clips still missing (limit reached?)")

    if a.check and made:
        check(made, jobs, clips_dir, texts_by_key, clips)
    return 0


def check(made, jobs, clips_dir, texts_by_key, clips):
    """Transcribe the clips generated in this run and print the ones whose words drift."""
    import difflib
    import re
    import soundfile as sf
    from faster_whisper import WhisperModel
    text_for = {}
    for key, roles in clips.items():
        for rel in roles.values():
            text_for[rel.split("/")[-1][:-4]] = texts_by_key[key]
    def norm(s):
        s = re.sub(r"\{[^}]+\}|\.\.\.|…", " ", s.lower().replace("’", "'"))
        return re.sub(r"[^a-z0-9' ]+", " ", s).split()
    model = WhisperModel("base.en", device="cpu", compute_type="int8")
    for cid in made:
        audio, sr = sf.read(str(clips_dir / f"{cid}.m4a"), dtype="float32")
        segs, _ = model.transcribe(audio, language="en", beam_size=5, condition_on_previous_text=False)
        heard = " ".join(s.text for s in segs).strip()
        ratio = difflib.SequenceMatcher(None, norm(text_for[cid]), norm(heard)).ratio()
        if ratio < 0.8:
            print(f"CHECK {ratio:.2f} {cid}  expected: {text_for[cid]!r}  heard: {heard!r}")


if __name__ == "__main__":
    sys.exit(main())
```

`tool/audio/README.md`: what the tool is (spec + ADR 0008 links), setup (`python -m venv` at a short path — Windows long-path failures otherwise — `pip install -r tool/audio/requirements.txt`), model download (kokoro `model.onnx` from `onnx-community/Kokoro-82M-v1.0-ONNX` saved as `tool/audio/models/kokoro-v1.0.onnx`, `voices-v1.0.bin` from the kokoro-onnx GitHub release), the commands above, how to add a speaker to `cast.json` or a word to `lexicon.json`, and the rule that a bundle edit is finished only when `generate_audio.py` has run and `flutter test test/content/levels` passes.

`.gitignore`: append `/tool/audio/models/` and `__pycache__/`.

- [ ] **Step 3: Smoke-run**

Run: `python tool/audio/generate_audio.py --level A1 --dry-run` — Expected: counts printed, unmapped speakers listed, no manifest written.
Run: `python tool/audio/generate_audio.py --level A1 --limit 5` — Expected: 5 clips in `assets/audio/en/A1/clips/`, a manifest with 5 references, a warning about the rest missing.

- [ ] **Step 4: Commit** — `git add tool/audio .gitignore && git commit -m "tool(audio): Kokoro engine, encoder, manifest and CLI"` (do not commit the 5 smoke clips yet; they are regenerated in Task 4).

---

### Task 4: Generate A1 and A2 audio

- [ ] **Step 1:** `python tool/audio/generate_audio.py --level A1 --prune` (~25 min on the authoring PC). Expected summary: ~1,530 clip references, ~12–15 MB.
- [ ] **Step 2:** `python tool/audio/generate_audio.py --level A2 --prune` (~70 min). Expected: ~1,620 references, ~35–40 MB.
- [ ] **Step 3:** Spot-check: `ls assets/audio/en/A1/clips | wc -l` equals the manifest reference count minus shared files; `python -c "import json;m=json.load(open('assets/audio/en/A1/manifest.json'));print(m['contentVersion'])"` equals the bundle's.
- [ ] **Step 4:** Commit the assets in their own commit: `git add assets/audio && git commit -m "content: bundled Kokoro speech clips for A1 and A2"`.

---

### Task 5: App — text keys, the clip index, the manifest parser

**Files:**
- Modify: `pubspec.yaml` (add `crypto: ^3.0.6` under dependencies)
- Create: `lib/features/speech/domain/speech_text.dart`
- Create: `lib/features/speech/domain/audio_clip_index.dart`
- Modify: `lib/features/activity_engine/presentation/widgets/phrase_text.dart` (remove `phraseForSpeech`, keep the widget; add `export '../../../speech/domain/speech_text.dart' show phraseForSpeech;` so the existing test keeps compiling)
- Test: `test/features/speech/audio_clip_index_test.dart`

**Interfaces:**
- Produces: `String phraseForSpeech(String)`; `const kTeacherRole = '_'`; `const kPartnerSpeaker = 'partner'`; `String normaliseSpeechText(String)`; `String textKeyFor(String)`; `class AudioManifest { levelId, contentVersion, clips: Map<String, Map<String,String>> (asset paths, resolved) ; factory parse(String json, {required String assetDirectory}) }`; `class AudioClipIndex { const AudioClipIndex.empty(); factory fromManifests(Iterable<AudioManifest>); String? assetPathFor(String text, {String? speaker}); int get clipCount; }`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';

void main() {
  // Shared with tool/audio/tests/test_textkey.py — change both or neither.
  const vectors = {
    'My name is {name}.': '4a712aa44408d872',
    '  My   name is {name}.\n': '4a712aa44408d872',
    'I\u2019m Omar.': 'fe69d774cfd057ee',
    "I'm Omar.": 'fe69d774cfd057ee',
    'Good morning.': '5c3e9f7ad0c9c2b8',
    "Hello! I'm Maya. Nice to meet you.": 'a29bdc5852db5cbf',
  };

  test('text keys match the authoring tool', () {
    vectors.forEach((text, key) => expect(textKeyFor(text), key, reason: text));
  });

  const manifestJson = '''
  {"schemaVersion": 1, "levelId": "a1", "contentVersion": "V1",
   "clips": {"4a712aa44408d872": {"_": "clips/aaaa.m4a"},
             "5c3e9f7ad0c9c2b8": {"Maya": "clips/bbbb.m4a", "Omar": "clips/cccc.m4a"}}}''';

  test('manifest paths are resolved against the asset directory', () {
    final m = AudioManifest.parse(manifestJson, assetDirectory: 'assets/audio/en/A1');
    expect(m.levelId, 'a1');
    expect(m.contentVersion, 'V1');
    expect(m.clips['4a712aa44408d872']!['_'], 'assets/audio/en/A1/clips/aaaa.m4a');
  });

  test('lookup prefers the speaker, then the teacher, then anything', () {
    final index = AudioClipIndex.fromManifests([
      AudioManifest.parse(manifestJson, assetDirectory: 'assets/audio/en/A1'),
    ]);
    expect(index.clipCount, 3);
    expect(index.assetPathFor('My name is {name}.'), 'assets/audio/en/A1/clips/aaaa.m4a');
    expect(index.assetPathFor('  My name is {name}. '), 'assets/audio/en/A1/clips/aaaa.m4a');
    expect(index.assetPathFor('Good morning.', speaker: 'Omar'), 'assets/audio/en/A1/clips/cccc.m4a');
    expect(index.assetPathFor('Good morning.', speaker: 'Sara'), 'assets/audio/en/A1/clips/bbbb.m4a');
    expect(index.assetPathFor('Good morning.'), 'assets/audio/en/A1/clips/bbbb.m4a');
    expect(index.assetPathFor('Not there.'), isNull);
    expect(const AudioClipIndex.empty().assetPathFor('Good morning.'), isNull);
  });

  test('a malformed manifest is a FormatException, not a crash elsewhere', () {
    expect(() => AudioManifest.parse('{"clips": 3}', assetDirectory: 'x'), throwsFormatException);
    expect(() => AudioManifest.parse('[]', assetDirectory: 'x'), throwsFormatException);
  });
}
```

- [ ] **Step 2: Run** — `flutter test test/features/speech/audio_clip_index_test.dart` — Expected: compile error, file missing.

- [ ] **Step 3: Implement**

`lib/features/speech/domain/speech_text.dart`:
```dart
/// A registry phrase's fill-in slots — `"My name is {name}."`.
final _placeholder = RegExp(r'\{(\w+)\}');

/// [text] as the device engine should speak it: each placeholder becomes a
/// pause. Bundled clips are keyed by the raw text and render the pause
/// themselves, so only the device fallback applies this.
String phraseForSpeech(String text) => text.replaceAll(_placeholder, '…');
```

`lib/features/speech/domain/audio_clip_index.dart`:
```dart
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The role a clip was rendered for: the teacher voice reads everything
/// that has no speaker (vocabulary, grammar, key phrases, transcripts).
const kTeacherRole = '_';

/// The `speaker` a caller passes for the other person in a speaking task.
const kPartnerSpeaker = 'partner';

/// The one text rule shared with `tool/audio/mohingo_audio/textkey.py`:
/// curly apostrophe to straight, whitespace runs to one space, trimmed.
/// No Unicode normalisation — the tool refuses non-NFC text instead.
String normaliseSpeechText(String text) => text
    .replaceAll('\u2019', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String textKeyFor(String text) =>
    sha1.convert(utf8.encode(normaliseSpeechText(text))).toString().substring(0, 16);

/// One level's `manifest.json` (schema in docs/DATA_MODEL.md), with clip
/// paths already resolved to full asset paths.
class AudioManifest {
  const AudioManifest({
    required this.levelId,
    required this.contentVersion,
    required this.clips,
  });

  factory AudioManifest.parse(String json, {required String assetDirectory}) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('audio manifest is not an object');
    }
    final rawClips = decoded['clips'];
    if (rawClips is! Map<String, dynamic>) {
      throw const FormatException('audio manifest has no clips map');
    }
    final clips = <String, Map<String, String>>{};
    rawClips.forEach((key, roles) {
      if (roles is! Map<String, dynamic>) {
        throw FormatException('clip entry $key is not a role map');
      }
      clips[key] = {
        for (final e in roles.entries)
          if (e.value is String) e.key: '$assetDirectory/${e.value as String}',
      };
    });
    return AudioManifest(
      levelId: decoded['levelId'] as String? ?? '',
      contentVersion: decoded['contentVersion'] as String? ?? '',
      clips: clips,
    );
  }

  final String levelId;
  final String contentVersion;

  /// textKey → role → asset path.
  final Map<String, Map<String, String>> clips;
}

/// Every bundled clip the app knows about, across all released levels.
class AudioClipIndex {
  const AudioClipIndex.empty() : _clips = const {};

  factory AudioClipIndex.fromManifests(Iterable<AudioManifest> manifests) {
    final merged = <String, Map<String, String>>{};
    for (final m in manifests) {
      m.clips.forEach((key, roles) {
        merged.putIfAbsent(key, () => {}).addAll(roles);
      });
    }
    return AudioClipIndex._(merged);
  }

  const AudioClipIndex._(this._clips);

  final Map<String, Map<String, String>> _clips;

  int get clipCount => _clips.values.fold(0, (n, roles) => n + roles.length);

  /// The clip for [text] in [speaker]'s voice, else the teacher's, else any.
  String? assetPathFor(String text, {String? speaker}) {
    final roles = _clips[textKeyFor(text)];
    if (roles == null || roles.isEmpty) return null;
    return roles[speaker ?? kTeacherRole] ?? roles[kTeacherRole] ?? roles.values.first;
  }
}
```

`phrase_text.dart`: delete the `_placeholder`-based `phraseForSpeech` function and its doc comment; add at the top `export '../../../speech/domain/speech_text.dart' show phraseForSpeech;`. Keep `_placeholder` for the widget.

- [ ] **Step 4: Run** — `flutter pub get && flutter test test/features/speech/audio_clip_index_test.dart test/features/activity_engine/presentation/phrase_text_test.dart` — Expected: pass.
- [ ] **Step 5: Commit** — `git add pubspec.yaml pubspec.lock lib/features/speech/domain test/features/speech/audio_clip_index_test.dart lib/features/activity_engine/presentation/widgets/phrase_text.dart && git commit -m "feat(speech): clip index keyed by the shared text rule"`

---

### Task 6: App — the `speaker` argument, the clip player and the bundled service

**Files:**
- Modify: `lib/features/speech/domain/text_to_speech_service.dart` (add `speaker`, `kNormalTtsRate`, doc)
- Modify: `lib/features/speech/data/device_text_to_speech_service.dart` (accept `speaker`, apply `phraseForSpeech`)
- Modify: `lib/features/speech/providers/tts_preferences_provider.dart` (`kDefaultTtsRate = kNormalTtsRate`)
- Create: `lib/features/speech/domain/clip_player.dart`, `lib/features/speech/data/audioplayers_clip_player.dart`, `lib/features/speech/data/bundled_audio_text_to_speech_service.dart`
- Modify: `test/features/speech/fake_speech_services.dart` (`speaker` recorded in `speakers`)
- Test: `test/features/speech/bundled_audio_text_to_speech_service_test.dart`

**Interfaces:**
- Produces: `speak(String text, {required String localeCode, double? rate, double? pitch, String? voiceName, String? speaker})`; `const kNormalTtsRate = 0.5`; `abstract interface class ClipPlayer { Future<void> play(String assetPath, {double playbackRate = 1.0, Duration? timeout}); Future<void> stop(); }`; `BundledAudioTextToSpeechService({required Future<AudioClipIndex> index, required ClipPlayer player, required TextToSpeechService fallback})` with `static double playbackRateFor(double? rate)` and `static Duration playbackTimeout(String text, double playbackRate)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/speech/data/bundled_audio_text_to_speech_service.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';
import 'package:mohingo/features/speech/domain/clip_player.dart';
import 'package:mohingo/features/speech/domain/text_to_speech_service.dart';

import 'fake_speech_services.dart';

class FakeClipPlayer implements ClipPlayer {
  final played = <(String, double)>[];
  bool stopped = false;
  bool failNext = false;
  Completer<void>? current;

  @override
  Future<void> play(String assetPath, {double playbackRate = 1.0, Duration? timeout}) async {
    if (failNext) {
      failNext = false;
      throw StateError('cannot play');
    }
    played.add((assetPath, playbackRate));
    current = Completer<void>();
    await current!.future;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    current?.complete();
  }
}

void main() {
  const manifest = '{"levelId":"a1","contentVersion":"v","clips":{'
      '"5c3e9f7ad0c9c2b8":{"_":"clips/t.m4a","Omar":"clips/o.m4a"}}}';
  final index = AudioClipIndex.fromManifests([
    AudioManifest.parse(manifest, assetDirectory: 'assets/audio/en/A1'),
  ]);

  late FakeClipPlayer player;
  late FakeTextToSpeechService fallback;
  late BundledAudioTextToSpeechService service;

  setUp(() {
    player = FakeClipPlayer();
    fallback = FakeTextToSpeechService();
    service = BundledAudioTextToSpeechService(
      index: Future.value(index),
      player: player,
      fallback: fallback,
    );
  });

  test('plays the clip for the speaker and reports playing then stopped', () async {
    final states = <TtsPlaybackState>[];
    final sub = service.playbackState.listen(states.add);
    final done = service.speak('Good morning.', localeCode: 'en', speaker: 'Omar', rate: 0.5);
    await Future<void>.delayed(Duration.zero);
    expect(player.played, [('assets/audio/en/A1/clips/o.m4a', 1.0)]);
    expect(fallback.spoken, isEmpty);
    player.current!.complete();
    await done;
    expect(states, [TtsPlaybackState.playing, TtsPlaybackState.stopped]);
    await sub.cancel();
  });

  test('falls back to the device engine when there is no clip', () async {
    await service.speak('Not bundled.', localeCode: 'en', rate: 0.5, speaker: 'Omar');
    expect(player.played, isEmpty);
    expect(fallback.spoken, ['Not bundled.']);
    expect(fallback.speakers, ['Omar']);
  });

  test('falls back when the player throws', () async {
    player.failNext = true;
    await service.speak('Good morning.', localeCode: 'en');
    expect(fallback.spoken, ['Good morning.']);
  });

  test('maps the flutter_tts rate scale to playback rate', () {
    expect(BundledAudioTextToSpeechService.playbackRateFor(null), 1.0);
    expect(BundledAudioTextToSpeechService.playbackRateFor(0.5), 1.0);
    expect(BundledAudioTextToSpeechService.playbackRateFor(0.3), closeTo(0.6, 1e-9));
    expect(BundledAudioTextToSpeechService.playbackRateFor(0.25), 0.6);
    expect(BundledAudioTextToSpeechService.playbackRateFor(1.0), 1.5);
  });

  test('stop stops the player and the fallback', () async {
    final done = service.speak('Good morning.', localeCode: 'en');
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    await done;
    expect(player.stopped, isTrue);
  });

  test('an index that failed to load means the device engine speaks', () async {
    final broken = BundledAudioTextToSpeechService(
      index: Future.error(StateError('no manifest')),
      player: player,
      fallback: fallback,
    );
    await broken.speak('Good morning.', localeCode: 'en');
    expect(fallback.spoken, ['Good morning.']);
  });
}
```

Update `FakeTextToSpeechService`: add `final List<String?> speakers = [];`, add `String? speaker` to `speak`, and `speakers.add(speaker);`.

- [ ] **Step 2: Run** — Expected: compile errors (`speaker` unknown, files missing).

- [ ] **Step 3: Implement**

`text_to_speech_service.dart`: replace the interface's doc comment with the bundled-first description (clips first, device engine as fallback; see ADR 0008), add
```dart
/// flutter_tts's rate scale runs 0.0–1.0 with this value as normal speed;
/// bundled clips map it to a playback rate (see BundledAudioTextToSpeechService).
const kNormalTtsRate = 0.5;
```
and to `speak`:
```dart
    /// Who is speaking, when the content says: a dialogue speaker label or
    /// [kPartnerSpeaker]. Chooses the voice of a bundled clip; the device
    /// engine ignores it.
    String? speaker,
```

`device_text_to_speech_service.dart`: add the `speaker` parameter (unused), import `../domain/speech_text.dart`, and speak `phraseForSpeech(text)` instead of `text` (the timeout keeps using the same string).

`tts_preferences_provider.dart`: `const kDefaultTtsRate = kNormalTtsRate;` with the import.

`clip_player.dart`:
```dart
/// Plays one bundled clip at a time. The seam that keeps `audioplayers`
/// out of the speech service, so tests can play nothing.
abstract interface class ClipPlayer {
  /// Plays the asset at [assetPath] (a pubspec asset path such as
  /// `assets/audio/en/A1/clips/x.m4a`) at [playbackRate], pitch preserved.
  /// Completes when the clip ends, [stop] is called, or [timeout] passes.
  Future<void> play(String assetPath, {double playbackRate = 1.0, Duration? timeout});

  Future<void> stop();
}
```

`audioplayers_clip_player.dart`:
```dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../domain/clip_player.dart';

/// One shared [AudioPlayer]: a speak request always replaces the previous
/// clip, which is exactly the "newer request wins" rule the widgets keep.
///
/// **Not verified on a real device** (see README "Known limitations").
class AudioplayersClipPlayer implements ClipPlayer {
  AudioplayersClipPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _player;
  Completer<void>? _done;

  static String _assetName(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

  @override
  Future<void> play(String assetPath, {double playbackRate = 1.0, Duration? timeout}) async {
    await stop();
    final done = _done = Completer<void>();
    final sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _player.setPlaybackRate(playbackRate);
      await _player.play(AssetSource(_assetName(assetPath)));
      await done.future.timeout(timeout ?? const Duration(minutes: 3), onTimeout: () {});
    } finally {
      await sub.cancel();
      if (identical(_done, done)) _done = null;
    }
  }

  @override
  Future<void> stop() async {
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
    await _player.stop();
  }
}
```

`bundled_audio_text_to_speech_service.dart`:
```dart
import 'dart:async';

import '../domain/audio_clip_index.dart';
import '../domain/clip_player.dart';
import '../domain/text_to_speech_service.dart';

/// Plays the bundled clip for a text when there is one, and hands anything
/// else to the device engine. See ADR 0008.
class BundledAudioTextToSpeechService implements TextToSpeechService {
  BundledAudioTextToSpeechService({
    required Future<AudioClipIndex> index,
    required ClipPlayer player,
    required TextToSpeechService fallback,
  }) : _index = index.catchError((Object _) => const AudioClipIndex.empty()),
       _player = player,
       _fallback = fallback {
    _fallbackSub = _fallback.playbackState.listen(_state.add);
  }

  final Future<AudioClipIndex> _index;
  final ClipPlayer _player;
  final TextToSpeechService _fallback;
  final _state = StreamController<TtsPlaybackState>.broadcast();
  // ignore: unused_field
  late final StreamSubscription<TtsPlaybackState> _fallbackSub;

  /// The learner's rate (flutter_tts scale, [kNormalTtsRate] = normal) as a
  /// playback rate. Clamped so "Slower" stays intelligible and nothing
  /// becomes a chipmunk.
  static double playbackRateFor(double? rate) =>
      rate == null ? 1.0 : (rate / kNormalTtsRate).clamp(0.6, 1.5).toDouble();

  /// Longer than any clip could be at [playbackRate], so a player that never
  /// reports completion cannot pin a play button forever.
  static Duration playbackTimeout(String text, double playbackRate) =>
      Duration(milliseconds: ((5 + text.length / 6) * 1000 / playbackRate).round());

  @override
  Stream<TtsPlaybackState> get playbackState => _state.stream;

  @override
  Future<List<TtsVoice>> availableVoicesForLocale(String localeCode) =>
      _fallback.availableVoicesForLocale(localeCode);

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
    String? speaker,
  }) async {
    final path = (await _index).assetPathFor(text, speaker: speaker);
    if (path != null) {
      final playbackRate = playbackRateFor(rate);
      _state.add(TtsPlaybackState.playing);
      try {
        await _player.play(
          path,
          playbackRate: playbackRate,
          timeout: playbackTimeout(text, playbackRate),
        );
        return;
      } catch (_) {
        // A clip that will not play is no reason to say nothing.
      } finally {
        _state.add(TtsPlaybackState.stopped);
      }
    }
    await _fallback.speak(
      text,
      localeCode: localeCode,
      rate: rate,
      pitch: pitch,
      voiceName: voiceName,
      speaker: speaker,
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _fallback.stop();
  }
}
```

- [ ] **Step 4: Run** — `flutter test test/features/speech` — Expected: pass. Then `flutter test` for the fakes' compile across the suite.
- [ ] **Step 5: Commit** — `git commit -am "feat(speech): bundled clips play first, device engine falls back"` (plus `git add` for the new files).

---

### Task 7: App — providers, catalogue, assets, call sites, Settings

**Files:**
- Modify: `lib/content/catalog/level_catalog.dart` (`audioManifestAssetPath` on the entry, the two levels, `applyPreviewOverrides`)
- Modify: `lib/features/speech/providers/speech_providers.dart` (+ regenerate `.g.dart` with build_runner)
- Modify: `pubspec.yaml` (assets: `assets/audio/en/A1/`, `assets/audio/en/A1/clips/`, `assets/audio/en/A2/`, `assets/audio/en/A2/clips/`)
- Modify: `lib/features/lesson_player/presentation/widgets/lesson_conversation_step.dart:86-91` (`speaker: widget.lines[i].speaker`)
- Modify: `lib/features/activity_engine/presentation/widgets/activity_partner_turns_card.dart:67` (`speaker: kPartnerSpeaker`)
- Modify: `lib/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart:58-65` (speak `text`, drop the `phrase_text.dart` import if only used for that)
- Modify: `lib/features/settings/presentation/settings_screen.dart` (remove the pitch `_Block` at 84-88 and `_TtsPitchSlider` 689-705; `_TtsRateBlock` stops reading pitch)
- Tests: extend `test/features/lesson_player/lesson_intro_test.dart` (conversation passes the speaker), `test/features/activity_engine/speak_activity_view_test.dart` (partner turns pass `kPartnerSpeaker`), `test/features/lesson_player/lesson_key_phrases_step_test.dart` (raw phrase spoken); settings tests that referenced the pitch slider, if any, updated.

- [ ] **Step 1: Write/extend the failing tests** — in each of the three widget tests, after the existing "speaks …" expectation add the matching `expect(tts.speakers, [...])`; in the key-phrases test expect `tts.spoken` to contain `'My name is {name}.'` (raw), not `'My name is ….'`.
- [ ] **Step 2: Run** — Expected: the new expectations fail.
- [ ] **Step 3: Implement**

`speech_providers.dart` additions:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../content/providers/course_content_providers.dart';
import '../data/audioplayers_clip_player.dart';
import '../data/bundled_audio_text_to_speech_service.dart';
import '../domain/audio_clip_index.dart';
import '../domain/clip_player.dart';

/// Every released level's clip manifest, merged. A level whose manifest is
/// missing or malformed contributes nothing and is logged — the app must
/// never fail to start over audio, it just falls back to the device engine.
@Riverpod(keepAlive: true)
Future<AudioClipIndex> audioClipIndex(Ref ref) async {
  final manifests = <AudioManifest>[];
  for (final entry in ref.watch(levelCatalogProvider)) {
    final path = entry.audioManifestAssetPath;
    if (path == null) continue;
    try {
      final json = await rootBundle.loadString(path);
      manifests.add(AudioManifest.parse(json, assetDirectory: p.dirname(path)));
    } catch (e) {
      debugPrint('audio manifest $path unusable: $e');
    }
  }
  return AudioClipIndex.fromManifests(manifests);
}

@Riverpod(keepAlive: true)
ClipPlayer clipPlayer(Ref ref) => AudioplayersClipPlayer();

@Riverpod(keepAlive: true)
TextToSpeechService textToSpeechService(Ref ref) {
  return BundledAudioTextToSpeechService(
    index: ref.watch(audioClipIndexProvider.future),
    player: ref.watch(clipPlayerProvider),
    fallback: DeviceTextToSpeechService(),
  );
}
```
Then `dart run build_runner build --delete-conflicting-outputs`.

`level_catalog.dart`: add `this.audioManifestAssetPath` to the constructor, a documented `final String? audioManifestAssetPath;` ("The level's bundled speech clips, see ADR 0008; null while a level has none"), set `'assets/audio/en/A1/manifest.json'` / `'assets/audio/en/A2/manifest.json'`, and copy it in `applyPreviewOverrides`.

Call sites: as listed in Files. Settings: delete the pitch block and slider; `_TtsRateBlock` calls `speak(_sample, localeCode: 'en', rate: rate)`.

- [ ] **Step 4: Run** — `flutter analyze && flutter test test/features/lesson_player test/features/activity_engine test/features/settings test/content` — Expected: pass.
- [ ] **Step 5: Commit** — `git commit -m "feat(speech): app plays bundled clips; speakers reach the speech service"`

---

### Task 8: App — `SpeakableStrings` and the audio gate

**Files:**
- Create: `lib/content/audio/speakable_strings.dart`
- Modify: `test/content/levels/level_gate_config.dart` (`audioManifestAssetPath`, `audioBudgetBytes` on `LevelGateConfig`; set on `_a1`/`_a2`)
- Create: `test/content/levels/level_audio_test.dart`
- Modify: `test/content/levels/level_config_test.dart` (catalogue path == gate path)
- Test: `test/content/audio/speakable_strings_test.dart`

**Interfaces:**
- Produces: `class Speakable { final String text; final String role; final String source; }`, `List<Speakable> speakableStringsOf(CourseBundle bundle)`.

- [ ] **Step 1: Write the failing tests**

`test/content/audio/speakable_strings_test.dart` — parse a small bundle JSON through `CourseBundleParser.parse` mirroring Task 2's tiny bundle (it must satisfy the parser's required fields; copy the minimal valid bundle from an existing parser test, e.g. `test/content/parsing/*_test.dart`), then assert the same `(text, role)` set as the Python test; and for the real bundles assert `{(textKeyFor(s.text), s.role)}.length` is 1533 for A1 (the value pinned in Task 2) and 1623 for A2.

`test/content/levels/level_audio_test.dart`:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/audio/speakable_strings.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';
import 'package:path/path.dart' as p;

import 'level_gate_config.dart';

/// A released level ships a clip for every string the app speaks (ADR 0008).
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      final manifestFile = File(gate.audioManifestAssetPath);
      final dir = p.dirname(gate.audioManifestAssetPath);

      test('ships a manifest generated for its contentVersion', () {
        expect(manifestFile.existsSync(), isTrue, reason: gate.audioManifestAssetPath);
        final m = AudioManifest.parse(manifestFile.readAsStringSync(), assetDirectory: dir);
        expect(m.levelId, gate.levelId);
        expect(m.contentVersion, gate.bundle().contentVersion,
            reason: 'regenerate audio: python tool/audio/generate_audio.py --level ${gate.levelId.toUpperCase()}');
      });

      test('has a clip for every speakable string in the role the app asks for', () {
        final m = AudioManifest.parse(manifestFile.readAsStringSync(), assetDirectory: dir);
        final missing = <String>[];
        for (final s in speakableStringsOf(gate.bundle())) {
          final roles = m.clips[textKeyFor(s.text)];
          if (roles == null || !roles.containsKey(s.role)) missing.add('${s.source}: ${s.text}');
        }
        expect(missing, isEmpty, reason: 'first missing: ${missing.take(20).join('\n')}');
      });

      test('every referenced clip exists and every clip is referenced', () {
        final m = AudioManifest.parse(manifestFile.readAsStringSync(), assetDirectory: dir);
        final referenced = {for (final roles in m.clips.values) ...roles.values};
        for (final path in referenced) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
        final onDisk = Directory('$dir/clips').listSync().whereType<File>()
            .map((f) => p.join(dir, 'clips', p.basename(f.path)).replaceAll('\\', '/')).toSet();
        expect(onDisk.difference(referenced), isEmpty, reason: 'orphan clips: run generate_audio.py --prune');
      });

      test('stays within its audio budget', () {
        final bytes = Directory('$dir/clips').listSync().whereType<File>().fold<int>(0, (n, f) => n + f.lengthSync());
        expect(bytes, lessThanOrEqualTo(gate.audioBudgetBytes), reason: '$bytes bytes');
      });
    });
  }
}
```

`level_config_test.dart`: add, inside the existing per-gate group, `expect(levelCatalogEntry(gate.levelId)!.audioManifestAssetPath, gate.audioManifestAssetPath);`.

- [ ] **Step 2: Run** — Expected: compile errors for the new symbols.

- [ ] **Step 3: Implement**

`lib/content/audio/speakable_strings.dart`:
```dart
import '../models/activity.dart';
import '../models/course_bundle.dart';
import '../../features/speech/domain/audio_clip_index.dart';

/// One string the app hands to `TextToSpeechService.speak`, with the role
/// the call site asks for. Mirrors `tool/audio/mohingo_audio/speakables.py`;
/// the level gate holds the tool's manifest to this list.
class Speakable {
  const Speakable({required this.text, required this.role, required this.source});

  final String text;
  final String role;
  final String source;
}

List<Speakable> speakableStringsOf(CourseBundle bundle) {
  final out = <Speakable>[];
  void activity(Activity a, String where) {
    if (a is AudioChoiceActivity) {
      final t = a.audioTranscript?.trim();
      if (t != null && t.isNotEmpty) {
        out.add(Speakable(text: t, role: kTeacherRole, source: '$where/${a.id}.audioTranscript'));
      }
    }
    if (a is SpeakActivity) {
      for (final (i, turn) in a.partnerTurns.indexed) {
        out.add(Speakable(text: turn.trim(), role: kPartnerSpeaker, source: '$where/${a.id}.partnerTurns[$i]'));
      }
    }
  }

  for (final u in bundle.units) {
    for (final l in u.lessons) {
      for (final (i, line) in l.encounterDialogue.indexed) {
        if (line.en.trim().isNotEmpty) {
          out.add(Speakable(text: line.en.trim(), role: line.speaker, source: '${l.id} dialogue[$i]'));
        }
      }
      final rt = l.readingText?.text.trim();
      if (rt != null && rt.isNotEmpty) {
        out.add(Speakable(text: rt, role: kTeacherRole, source: '${l.id} readingText'));
      }
      for (final a in l.activities) {
        activity(a, l.id);
      }
    }
  }
  for (final c in bundle.chunks) {
    out.add(Speakable(text: c.text.trim(), role: kTeacherRole, source: 'chunk ${c.id}'));
  }
  for (final x in bundle.lexicon) {
    out.add(Speakable(text: x.headword.trim(), role: kTeacherRole, source: 'lexicon ${x.id}'));
    for (final (i, ex) in x.examples.indexed) {
      if (ex.en.trim().isNotEmpty) {
        out.add(Speakable(text: ex.en.trim(), role: kTeacherRole, source: 'lexicon ${x.id} example[$i]'));
      }
    }
  }
  for (final g in bundle.grammar) {
    out.add(Speakable(text: g.form.trim(), role: kTeacherRole, source: 'grammar ${g.id}'));
    for (final (i, ex) in g.examples.indexed) {
      if (ex.en.trim().isNotEmpty) {
        out.add(Speakable(text: ex.en.trim(), role: kTeacherRole, source: 'grammar ${g.id} example[$i]'));
      }
    }
  }
  for (final a in bundle.finalMission.activities) {
    activity(a, 'finalMission');
  }
  for (final e in bundle.finalAssessment.sections.entries) {
    for (final a in e.value.activities) {
      activity(a, 'finalAssessment.${e.key}');
    }
  }
  return [for (final s in out) if (s.text.isNotEmpty) s];
}
```
(If any `AudioChoiceActivity`'s transcript is spoken by a different activity type in the app — check `activity_view_registry.dart` — include that type too. `DialogueActivity` has no spoken fields.)

`level_gate_config.dart`: add `required this.audioManifestAssetPath, this.audioBudgetBytes = 60 * 1024 * 1024,` to the constructor, the two fields with docs ("the clips a released level ships — ADR 0008 — and how large they may be, so a level cannot push the app past Play's mobile-data threshold without a decision"), and values `'assets/audio/en/A1/manifest.json'` / `'assets/audio/en/A2/manifest.json'`.

- [ ] **Step 4: Run** — `flutter test test/content` — Expected: pass (Task 4's audio must be on disk).
- [ ] **Step 5: Commit** — `git commit -m "test(levels): a released level ships a clip for every spoken string"`

---

### Task 9: Docs

**Files:** `docs/TECH_STACK.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/LEVEL_STANDARD.md`, `docs/TESTING.md`, `docs/GLOSSARY.md`, `docs/CONVENTIONS.md`, `docs/SECURITY.md`, `docs/ROADMAP.md`, `README.md`, `CLAUDE.md`.

- [ ] **Step 1:** For each file, `grep -n` for the lines the spec names ("no pre-recorded audio", `ttsSource`, `flutter_tts`, "Known limitations", the level-cost table, the definition-of-done table) and rewrite them to the bundled-audio truth: engine and tool in TECH_STACK; the speech layer paragraph and the tool boundary in ARCHITECTURE; the manifest schema in DATA_MODEL; "a level ships its audio" plus the size cost and the 60 MB budget in LEVEL_STANDARD; `level_audio_test.dart`, the pytest suite and `--check` in TESTING; clip / manifest / role / cast / text key in GLOSSARY; `tool/audio/` is Python in CONVENTIONS; the tool-credentials rule in SECURITY; on-demand audio packs deferred in ROADMAP; tool setup, app size and the device caveat in README; the header, the "Commands" block (`audio: python tool/audio/generate_audio.py --level A1`) and the definition-of-done row ("A spoken bundle string added or changed → regenerate the level's audio") in CLAUDE.md. Bump every touched Last-verified line to 2026-09-22 (`feature/bundled-audio`).
- [ ] **Step 2:** `git commit -am "docs: bundled speech audio across the docs"`

---

### Task 10: Verification and hand-off

- [ ] `dart format --set-exit-if-changed . && flutter analyze` — no issues.
- [ ] `flutter test` — all pass; note the count.
- [ ] `python -m pytest tool/audio/tests -q` — pass.
- [ ] `python tool/audio/generate_audio.py --level A1 --dry-run` — "0 to generate", no unmapped speakers except role labels.
- [ ] `git status` clean; `git log --oneline main..` shows the task commits.
- [ ] Report to the owner: what shipped, the sizes, the three ear-checks still open, and that no device has played a clip in this environment.

## Self-review

- Spec coverage: engine/tool (T1–T4), manifest + index + player + service (T5–T6), providers/catalogue/assets/call sites/Settings (T7), gate + SpeakableStrings (T8), docs (T9), verification (T10). Non-goals untouched.
- Placeholders: the A1 (textKey, role) count is pinned when Task 2 first runs and reused in Task 8; everything else is concrete.
- Type consistency: `speak(..., String? speaker)` everywhere; `ClipPlayer.play(assetPath, {playbackRate, timeout})`; `AudioManifest.parse(json, assetDirectory:)`; `AudioClipIndex.assetPathFor(text, speaker:)`; `kTeacherRole`/`kPartnerSpeaker` in `audio_clip_index.dart`; `speakableStringsOf(bundle)`.
