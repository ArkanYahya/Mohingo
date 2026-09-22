import json
from pathlib import Path

from mohingo_audio.speakables import PARTNER, TEACHER, known_speakers, speakables_of
from mohingo_audio.textkey import text_key

ROOT = Path(__file__).resolve().parents[3]


def _bundle(level):
    path = ROOT / "assets/content/en" / level / f"{level.lower()}-course-bundle.json"
    return json.load(open(path, encoding="utf-8"))


def test_roles_from_a_tiny_bundle():
    b = {
        "units": [{"lessons": [{
            "id": "L1",
            "encounter": {"dialogue": [{"speaker": "Maya", "en": "Hi.", "ar": ""}]},
            "readingText": {"title": "t", "text": "A text."},
            "activities": [
                {"id": "A1", "audioTranscript": "Listen."},
                {"id": "A2", "partnerTurns": ["Turn one.", ""]},
                {"id": "A3", "examinerTurns": ["Old turn."]},
                {"id": "A4", "audioTranscript": ""},
            ],
        }]}],
        "chunks": [{"id": "C1", "text": "My name is {name}."}],
        "lexicon": [{"id": "X1", "headword": "name",
                     "examples": ["My name is Omar.", {"en": "Name?", "ar": ""}]}],
        "grammar": [{"id": "G1", "form": "I am", "examples": [{"en": "I'm Omar.", "ar": ""}]}],
        "finalMission": {"activities": [{"id": "M1", "audioTranscript": "Mission."}]},
        "finalAssessment": {"sections": {"listening": {"activities": [{"id": "S1", "partnerTurns": ["Assess."]}]}}},
    }
    got = {(s.text, s.role) for s in speakables_of(b)}
    assert got == {
        ("Hi.", "Maya"), ("A text.", TEACHER), ("Listen.", TEACHER), ("Turn one.", PARTNER),
        ("Old turn.", PARTNER), ("My name is {name}.", TEACHER), ("name", TEACHER),
        ("My name is Omar.", TEACHER), ("Name?", TEACHER), ("I am", TEACHER), ("I'm Omar.", TEACHER),
        ("Mission.", TEACHER), ("Assess.", PARTNER),
    }
    assert known_speakers(b) == {"Maya"}


def test_real_bundles_have_the_census_counts():
    # Pinned from the 2026-09-22 census; test/content/audio/speakable_strings_test.dart
    # pins the same numbers from the Dart side.
    a1 = speakables_of(_bundle("A1"))
    a2 = speakables_of(_bundle("A2"))
    assert len({(text_key(s.text), s.role) for s in a1}) == 1577
    assert len({(text_key(s.text), s.role) for s in a2}) == 1623
