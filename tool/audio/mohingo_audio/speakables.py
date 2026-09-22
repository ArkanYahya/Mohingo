"""Every string the app hands to TextToSpeechService.speak(), and the role it asks for.

Mirrors lib/content/audio/speakable_strings.dart; the Dart level gate is the source of
truth, so a call site added to the app must be added there and here together.
"""
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
        turns = a.get("examinerTurns")  # A1's older name for the same field
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
    return {
        line["speaker"]
        for u in bundle.get("units", [])
        for l in u.get("lessons", [])
        for line in (l.get("encounter") or {}).get("dialogue", [])
        if line.get("speaker")
    }
