import pytest

from mohingo_audio.textkey import assert_nfc, normalise, text_key

# Shared with test/features/speech/audio_clip_index_test.dart — change both or neither.
VECTORS = {
    "My name is {name}.": "4a712aa44408d872",
    "  My   name is {name}.\n": "4a712aa44408d872",
    "I’m Omar.": "fe69d774cfd057ee",
    "I'm Omar.": "fe69d774cfd057ee",
    "Good morning.": "5c3e9f7ad0c9c2b8",
    "Hello! I'm Maya. Nice to meet you.": "a29bdc5852db5cbf",
}


def test_vectors():
    for text, key in VECTORS.items():
        assert text_key(text) == key, text


def test_normalise_collapses_whitespace_and_quotes():
    assert normalise("  a \t b\n") == "a b"
    assert normalise("I’m") == "I'm"


def test_refuses_non_nfc():
    with pytest.raises(ValueError):
        assert_nfc("café")  # decomposed é
    assert assert_nfc("café") is None
