"""kokoro-onnx wrapper.

The onnx-community export of Kokoro v1.0 wants `speed` as float and returns a [1, N]
waveform; kokoro-onnx feeds int32 (which would also truncate 0.85 to 0) and expects a
flat array, so its `_create_audio` is replaced with a dtype-correct copy.
"""
import types

import numpy as np

SR = 24000
PAUSE, TURN_GAP = 0.45, 0.5  # between segments of one string / between speaker turns
LEAD, TAIL, FADE = 0.10, 0.25, 0.03  # seconds
PEAK = 10 ** (-1 / 20)  # -1 dBFS


def silence(seconds: float) -> np.ndarray:
    return np.zeros(int(SR * seconds), dtype=np.float32)


def _create_audio(k, phonemes, voice, speed):
    import kokoro_onnx as ko

    phonemes = phonemes[: ko.MAX_PHONEME_LENGTH]
    tokens = np.array(k.tokenizer.tokenize(phonemes), dtype=np.int64)
    style = np.asarray(voice[len(tokens)], dtype=np.float32).reshape(1, -1)
    ids = np.array([[0, *tokens, 0]], dtype=np.int64)
    audio = k.sess.run(
        None,
        {"input_ids": ids, "style": style, "speed": np.array([speed], dtype=np.float32)},
    )[0]
    return np.asarray(audio, dtype=np.float32).reshape(-1), SR


class KokoroEngine:
    id = "kokoro-onnx/kokoro-v1.0"

    def __init__(self, model_path, voices_path, lexicon: dict[str, str], speed: float = 1.0):
        from kokoro_onnx import Kokoro

        from phonemizer.backend import EspeakBackend

        self.k = Kokoro(str(model_path), str(voices_path))
        self.k._create_audio = types.MethodType(_create_audio, self.k)
        self.speed = speed
        # One backend for the whole run: kokoro-onnx's phonemize() builds a new
        # espeak backend per call, which costs ~0.4 s each on Windows.
        self._backend = EspeakBackend("en-us", preserve_punctuation=True, with_stress=True)
        words = [w for w in lexicon if not w.startswith("_")]
        # word -> (phonemes Kokoro would produce on its own, phonemes we want)
        self._lex = {w: (ph, lexicon[w]) for w, ph in zip(words, self.phonemize_many(words))}

    def phonemize_many(self, texts: list[str]) -> list[str]:
        """The same output as kokoro-onnx's Tokenizer.phonemize, for many strings at once."""
        if not texts:
            return []
        vocab = self.k.tokenizer.vocab
        raw = self._backend.phonemize([t.strip() for t in texts], strip=True)
        return ["".join(ch for ch in p if ch in vocab).strip() for p in raw]

    def apply_lexicon(self, phonemes: str, text: str) -> str:
        lowered = text.lower()
        for word, (bad, good) in self._lex.items():
            if word.lower() in lowered and bad in phonemes:
                phonemes = phonemes.replace(bad, good)
        return phonemes

    def phonemes(self, text: str) -> str:
        return self.apply_lexicon(self.phonemize_many([text])[0], text)

    def _synth(self, phonemes: str, voice: str) -> np.ndarray:
        samples, sr = self.k.create(
            phonemes, voice=voice, speed=self.speed, lang="en-us", is_phonemes=True
        )
        assert sr == SR, sr
        return np.asarray(samples, dtype=np.float32)

    def render(self, parts: list[tuple[str, list[str]]]) -> np.ndarray:
        """parts: [(voice, [phoneme segment, ...]), ...].

        Segments of one part are joined with PAUSE, parts (speaker turns) with
        TURN_GAP; then lead-in, fade-out, tail and peak normalisation, so every
        clip starts cleanly, never ends abruptly, and plays at the same level.
        """
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
