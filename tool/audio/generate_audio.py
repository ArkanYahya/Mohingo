"""Generate the bundled speech clips for one level (ADR 0008).

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

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from mohingo_audio import manifest as mf  # noqa: E402
from mohingo_audio.cast import Cast  # noqa: E402
from mohingo_audio.speakables import TEACHER, Speakable, known_speakers, speakables_of  # noqa: E402
from mohingo_audio.speech import RULES_VERSION, segments_for, split_labelled  # noqa: E402
from mohingo_audio.textkey import assert_nfc, text_key  # noqa: E402

ROOT = HERE.parents[1]
ENGINE_ID = "kokoro-onnx/kokoro-v1.0"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
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

            models = Path(a.models)
            engine = KokoroEngine(models / "kokoro-v1.0.onnx", models / "voices-v1.0.bin", lexicon, a.speed)
        return engine

    lex_hash = hashlib.sha1(json.dumps(lexicon, sort_keys=True).encode("utf-8")).hexdigest()[:8]

    # 1. Plan: (textKey, role) -> the parts to render (voice + text segments).
    planned: dict[tuple[str, str], list[tuple[str, list[str]]]] = {}
    texts_by_key: dict[str, str] = {}
    for s in speakables:
        key = text_key(s.text)
        texts_by_key[key] = s.text
        if (key, s.role) in planned:
            continue
        labelled = split_labelled(s.text, speakers) if s.role == TEACHER else None
        if labelled:
            planned[(key, s.role)] = [(cast.voice_for(sp), segments_for(body)) for sp, body in labelled]
        else:
            planned[(key, s.role)] = [(cast.voice_for(s.role), segments_for(s.text))]

    # 2. Phonemes for every distinct segment in one batch, then the recipe that names each clip.
    # A dry run still uses the real recipe when the models are present, so its
    # "to generate / reused" counts are the ones a real run would see.
    segments = sorted({seg for parts in planned.values() for _, segs in parts for seg in segs})
    try:
        eng = get_engine()
    except Exception as e:  # noqa: BLE001 - a dry run must work without the models
        if not a.dry_run:
            raise
        print(f"(models not loadable: {e}; dry-run counts use text recipes and cannot report reuse)")
        eng = None
    if eng is None:
        phoneme_of = {seg: seg for seg in segments}
        stamp = [ENGINE_ID, a.speed, RULES_VERSION, lex_hash]
    else:
        phoneme_of = {seg: eng.apply_lexicon(ph, seg) for seg, ph in zip(segments, eng.phonemize_many(segments))}
        stamp = [ENGINE_ID, a.speed, RULES_VERSION]
    clips: dict[str, dict[str, str]] = {}
    jobs: dict[str, list[tuple[str, list[str]]]] = {}  # clipId -> [(voice, phoneme segments)]
    for (key, role), parts_text in planned.items():
        parts = [(v, [phoneme_of[seg] for seg in segs]) for v, segs in parts_text]
        recipe = json.dumps([*stamp, parts])
        clip_id = hashlib.sha1(recipe.encode("utf-8")).hexdigest()[:16]
        clips.setdefault(key, {})[role] = f"clips/{clip_id}.m4a"
        jobs[clip_id] = parts

    wanted = {f"clips/{cid}.m4a" for cid in jobs}
    todo = [cid for cid in jobs if a.force or not (clips_dir / f"{cid}.m4a").exists()]
    print(
        f"{level}: {len(speakables)} speakable strings, {len(clips)} distinct texts, "
        f"{len(jobs)} clips wanted, {len(todo)} to generate, {len(jobs) - len(todo)} reused"
    )
    if cast.unmapped:
        print("speakers not in cast.json (voice chosen by gender/hash):", ", ".join(sorted(cast.unmapped)))
    if a.dry_run:
        return 0

    # 2. Generate.
    import soundfile as sf

    from mohingo_audio.encode import to_m4a

    clips_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)
    made: list[str] = []
    t0, seconds = time.perf_counter(), 0.0
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
            print(f"  {i}/{len(todo)}  {time.perf_counter() - t0:.0f}s elapsed, {seconds:.0f}s of audio", flush=True)

    # 3. Manifest: only clips that exist on disk are recorded.
    present = {k: {r: p for r, p in roles.items() if (audio_dir / p).exists()} for k, roles in clips.items()}
    present = {k: v for k, v in present.items() if v}
    mf.write(audio_dir / "manifest.json", mf.build(level.lower(), bundle["contentVersion"], ENGINE_ID, a.speed, present))

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
    refs = sum(len(v) for v in present.values())
    print(f"manifest: {refs} clip references, {len(set(p for v in present.values() for p in v.values()))} files, {total / 1e6:.1f} MB")
    missing = [cid for cid in jobs if not (clips_dir / f"{cid}.m4a").exists()]
    if missing:
        print(f"WARNING: {len(missing)} clips still missing (limit reached?)")

    if a.check and made:
        check(made, clips_dir, texts_by_key, clips)
    return 0


def check(made, clips_dir, texts_by_key, clips):
    """Transcribe the clips generated in this run and print the ones whose words drift."""
    import difflib
    import re

    import soundfile as sf
    from faster_whisper import WhisperModel

    text_for: dict[str, str] = {}
    for key, roles in clips.items():
        for rel in roles.values():
            text_for[rel.split("/")[-1][:-4]] = texts_by_key[key]

    def norm(s):
        s = re.sub(r"\{[^}]+\}|\.\.\.|…", " ", s.lower().replace("’", "'"))
        return re.sub(r"[^a-z0-9' ]+", " ", s).split()

    model = WhisperModel("base.en", device="cpu", compute_type="int8")
    flagged = 0
    for cid in made:
        audio, _sr = sf.read(str(clips_dir / f"{cid}.m4a"), dtype="float32")
        segs, _ = model.transcribe(audio, language="en", beam_size=5, condition_on_previous_text=False)
        heard = " ".join(s.text for s in segs).strip()
        ratio = difflib.SequenceMatcher(None, norm(text_for[cid]), norm(heard)).ratio()
        if ratio < 0.8:
            flagged += 1
            print(f"CHECK {ratio:.2f} {cid}  expected: {text_for[cid]!r}  heard: {heard!r}")
    print(f"check: {flagged} of {len(made)} new clips drift from their text; listen to those")


if __name__ == "__main__":
    sys.exit(main())
