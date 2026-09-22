"""What the engine is actually given for a bundle string."""
import re

# Bump when segments_for/split_labelled change: every clip id changes, so the
# next run regenerates everything and --prune drops the old files.
RULES_VERSION = 1

_SLOT_OR_ELLIPSIS = re.compile(r"\{[^}]+\}|\.\.\.|…")
_LABEL = re.compile(r"(?:^|(?<=\s))([A-Z][A-Za-z']{1,20}):\s")


def segments_for(text: str) -> list[str]:
    """Split on {slots}, ellipses and ' / '; drop letterless pieces; keep a trailing
    ?/! on the last spoken piece so the question intonation survives.

    Pieces are joined with a pause by the engine. Kokoro would otherwise read
    "/" as "slash" and turn a bare "..." into noise.
    """
    text = text.strip()
    if " / " not in text and not _SLOT_OR_ELLIPSIS.search(text):
        return [text]
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
    """'Maya: Hi. Omar: Hello.' -> [('Maya','Hi.'), ('Omar','Hello.')].

    Only when every label is a dialogue speaker of the level and nothing precedes
    the first label; a monologue containing "You are right:" is left alone.
    Returns None when the text is not of that shape.
    """
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
