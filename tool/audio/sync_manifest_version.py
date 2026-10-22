"""Stamp a level's audio manifest with the bundle's current contentVersion
when a content change touched no spoken string.

  python tool/audio/sync_manifest_version.py --level A2

The level gate (test/content/levels/level_audio_test.dart) refuses a manifest
whose contentVersion lags its bundle. A change to prose that is never spoken
(a model answer, a rubric, Arabic) still bumps the bundle's contentVersion
(docs/CONVENTIONS.md), and regenerating the clips for it would need the
Kokoro models and an hour of compute to produce the same files. This script
checks instead: every speakable string of the bundle, in the role the app
asks for, already has a clip in the manifest, and no clip file is missing on
disk. Only then does it rewrite the version. If anything spoken did change,
it says so and exits non-zero — run generate_audio.py.
"""
import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from mohingo_audio import manifest as mf  # noqa: E402
from mohingo_audio.speakables import speakables_of  # noqa: E402
from mohingo_audio.textkey import text_key  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--level", required=True, help="A1, A2, ...")
    a = ap.parse_args()
    level = a.level.upper()
    bundle_path = ROOT / "assets/content/en" / level / f"{level.lower()}-course-bundle.json"
    audio_dir = ROOT / "assets/audio/en" / level
    bundle = json.load(open(bundle_path, encoding="utf-8"))
    manifest = mf.load(audio_dir / "manifest.json")
    if manifest is None:
        print(f"{level}: no manifest at {audio_dir / 'manifest.json'}; run generate_audio.py")
        return 1
    extras = json.load(open(HERE / "extra_strings.json", encoding="utf-8"))

    missing: list[str] = []
    for s in speakables_of(bundle):
        roles = manifest["clips"].get(text_key(s.text), {})
        if s.role not in roles:
            missing.append(f"{s.source}: {s.text[:60]!r} ({s.role})")
    for t in extras:
        if text_key(t) not in manifest["clips"]:
            missing.append(f"extra_strings.json: {t[:60]!r}")
    absent = sorted(p for p in mf.referenced_files(manifest) if not (audio_dir / p).exists())
    if missing or absent:
        for m in missing:
            print("no clip for", m)
        for p in absent:
            print("file missing", p)
        print(f"{level}: {len(missing)} spoken strings without a clip, {len(absent)} files missing; "
              "spoken content changed — run generate_audio.py")
        return 1

    old, new = manifest["contentVersion"], bundle["contentVersion"]
    if old == new:
        print(f"{level}: manifest already at {new}")
        return 0
    manifest["contentVersion"] = new
    mf.write(audio_dir / "manifest.json", manifest)
    print(f"{level}: manifest {old} -> {new}; every spoken string already has its clip")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
