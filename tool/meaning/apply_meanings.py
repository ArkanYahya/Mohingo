"""Apply and check the per-group *meanings* of ADR 0014.

  python tool/meaning/apply_meanings.py --level A1 --meanings FILE.json [--apply]
  python tool/meaning/apply_meanings.py --level A1            # check the bundle

A meaning is what one keyword group of a `keywordChecklist` rubric *means*:

  {"says": "The speaker says one thing they do not like.",
   "en": "one thing you don't like", "ar": "شيئاً لا تحبّه"}

`says` is a plain English statement about the answer's own content (never the
task's situation), which the on-device inference model checks the learner's
answer against; `en` and `ar` name the part for the learner and are what the
feedback lists as missing. FILE.json maps activity id -> list of meanings,
one per required group, in order.

Checks (on the file, or on the bundle without --meanings): one meaning per
group; `says` a statement ending in a full stop, no Arabic; `en` non-empty,
no Arabic; `ar` in Arabic script. With --apply, each activity's meanings are
inserted after its `"minGroupsMatched": N` line, textually, so the bundle
keeps its hand formatting; the result must still parse as JSON. Bump
`contentVersion` yourself and stamp the audio manifest
(tool/audio/sync_manifest_version.py).
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUNDLES = {
    "A1": ROOT / "assets/content/en/A1/a1-course-bundle.json",
    "A2": ROOT / "assets/content/en/A2/a2-course-bundle.json",
}
ARABIC = re.compile(r"[؀-ۿ]")


def keyword_tasks(bundle: dict, *, mastery_only: bool = True):
    for u in bundle["units"]:
        for l in u["lessons"]:
            for a in l["activities"]:
                ev = a.get("evaluation")
                if a["type"] in ("speak", "write") and isinstance(ev, dict) \
                        and ev.get("type") == "keywordChecklist" \
                        and (not mastery_only or a.get("mode") == "mastery"):
                    yield a


def problems(activity: dict, meanings) -> list[str]:
    out = []
    groups = activity["evaluation"]["requiredGroups"]
    if not isinstance(meanings, list) or len(meanings) != len(groups):
        return [f"{activity['id']}: {len(meanings) if isinstance(meanings, list) else 'no'} meanings for {len(groups)} groups"]
    for i, m in enumerate(meanings):
        if not isinstance(m, dict) or set(m) != {"says", "en", "ar"}:
            out.append(f"{activity['id']} G{i}: keys must be says/en/ar")
            continue
        says, en, ar = m["says"].strip(), m["en"].strip(), m["ar"].strip()
        if not says.endswith(".") or ARABIC.search(says) or len(says.split()) < 3:
            out.append(f"{activity['id']} G{i}: says is not an English statement: {says!r}")
        if not en or ARABIC.search(en):
            out.append(f"{activity['id']} G{i}: en is empty or not English: {en!r}")
        if not ARABIC.search(ar):
            out.append(f"{activity['id']} G{i}: ar is not Arabic: {ar!r}")
    return out


def apply_textually(path: Path, by_id: dict[str, list]) -> None:
    text = path.read_text(encoding="utf-8")
    for activity_id, meanings in by_id.items():
        start = text.index(f'"id": "{activity_id}"')
        end = text.find('"id": "', start + 1)
        segment = text[start:end if end != -1 else len(text)]
        if '"meanings":' in segment:
            raise SystemExit(f"{activity_id}: already has meanings")
        m = re.search(r'^(\s*)"minGroupsMatched": (\d+)(,?)\n', segment, re.M)
        if not m:
            raise SystemExit(f"{activity_id}: no minGroupsMatched line")
        indent, trailing = m.group(1), m.group(3)
        lines = [f'{indent}"minGroupsMatched": {m.group(2)},', f'{indent}"meanings": [']
        for i, mm in enumerate(meanings):
            body = json.dumps({"says": mm["says"], "en": mm["en"], "ar": mm["ar"]}, ensure_ascii=False)
            lines.append(f'{indent}  {body}' + ("," if i < len(meanings) - 1 else ""))
        # Keep the comma the original line carried: another key (such as
        # onlineRefinement) follows the meanings then.
        lines.append(f'{indent}]{trailing}')
        segment = segment[:m.start()] + "\n".join(lines) + "\n" + segment[m.end():]
        text = text[:start] + segment + text[start + len(text[start:end if end != -1 else len(text)]):]
    json.loads(text)  # must still parse
    path.write_text(text, encoding="utf-8", newline="\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--level", required=True, choices=sorted(BUNDLES))
    ap.add_argument("--meanings", help="JSON {activityId: [meaning, ...]}")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    path = BUNDLES[args.level]
    bundle = json.loads(path.read_text(encoding="utf-8"))
    tasks = {a["id"]: a for a in keyword_tasks(bundle)}
    bad: list[str] = []
    if args.meanings:
        proposed = json.loads(Path(args.meanings).read_text(encoding="utf-8"))
        unknown = sorted(set(proposed) - set(tasks))
        if unknown:
            bad.append(f"not keyword-graded mastery tasks of {args.level}: {unknown}")
        for aid, ms in proposed.items():
            if aid in tasks:
                bad.extend(problems(tasks[aid], ms))
        missing = sorted(set(tasks) - set(proposed))
        print(f"{len(proposed)} tasks proposed, {len(missing)} of {len(tasks)} mastery tasks without a proposal")
        if missing:
            print("  missing:", " ".join(missing))
    else:
        covered = 0
        for a in tasks.values():
            ms = a["evaluation"].get("meanings")
            if ms is None:
                continue
            covered += 1
            bad.extend(problems(a, ms))
        print(f"{covered} of {len(tasks)} mastery tasks carry meanings in the bundle")
    for line in bad:
        print("  ", line)
    if bad:
        return 1
    if args.meanings and args.apply:
        apply_textually(path, {aid: ms for aid, ms in proposed.items() if aid in tasks})
        print(f"applied to {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
