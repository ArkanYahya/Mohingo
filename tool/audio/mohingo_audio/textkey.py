"""The one text rule shared with the app (lib/features/speech/domain/audio_clip_index.dart).

Both sides must produce the same key for the same bundle string, so this file and
`textKeyFor` in Dart are pinned by the same test vectors (tests/test_textkey.py and
test/features/speech/audio_clip_index_test.dart).
"""
import hashlib
import re
import unicodedata

_WS = re.compile(r"\s+")


def normalise(text: str) -> str:
    return _WS.sub(" ", text.replace("’", "'")).strip()


def text_key(text: str) -> str:
    return hashlib.sha1(normalise(text).encode("utf-8")).hexdigest()[:16]


def assert_nfc(text: str) -> None:
    """The app cannot normalise Unicode, so authored text must already be NFC."""
    if unicodedata.normalize("NFC", text) != text:
        raise ValueError(f"text is not NFC-normalised: {text!r}")
