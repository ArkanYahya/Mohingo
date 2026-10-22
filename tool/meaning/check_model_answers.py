"""Validate the model answers that ADR 0011's meaning signal relies on.

  python tool/meaning/check_model_answers.py [--answers FILE.json] [--apply]

Two checks, over every mastery `speak`/`write` task graded by a keyword
checklist, in every shipped bundle:

1. Each model answer (the task's `accepted` list, or the proposed answers in
   --answers before they are applied) must pass its own rubric, with the same
   word-boundary keyword matching the app's evaluator uses. The level gate
   (`level_answerable_test.dart`) enforces this in Dart; this mirror lets an
   author check a batch before touching the bundle.
2. A `write` task's model answer should sit inside its `wordGuide`.

With --apply, the proposed answers are written into the bundles' `accepted`
lists (only where the list is empty), by editing the `"accepted": []` of each
activity in place so the file keeps its hand formatting. Bump
`contentVersion` yourself.
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


def mentions(answer: str, keyword: str) -> bool:
    """`_mentionsKeyword` in lib/features/activity_engine/domain/evaluation/evaluator.dart."""
    kw = keyword.strip()
    if not kw:
        return False
    body = r"\s+".join(re.escape(w) for w in kw.split())
    prefix = r"\b" if re.match(r"^\w", kw) else ""
    suffix = r"\b" if re.search(r"\w$", kw) else ""
    return re.search(prefix + body + suffix, answer, re.IGNORECASE) is not None


def passes(answer: str, spec: dict) -> tuple[bool, int]:
    matched = sum(1 for g in spec["requiredGroups"] if any(mentions(answer, k) for k in g))
    return matched >= spec["minGroupsMatched"], matched


def tasks(bundle: dict):
    for u in bundle["units"]:
        for l in u["lessons"]:
            for a in l["activities"]:
                ev = a.get("evaluation")
                if a["type"] in ("speak", "write") and a.get("mode") == "mastery" \
                        and isinstance(ev, dict) and ev.get("type") == "keywordChecklist":
                    yield a


def apply_textually(path: Path, answers: dict[str, str]) -> None:
    """Replace each activity's `"accepted": []` with its answer, in place."""
    text = open(path, encoding="utf-8").read()
    for activity_id, answer in answers.items():
        start = text.index(f'"id": "{activity_id}"')
        end = text.find('"id": "', start + 1)
        segment = text[start:end if end != -1 else len(text)]
        target = '"accepted": []'
        if segment.count(target) != 1:
            raise SystemExit(f"{activity_id}: expected one empty accepted list, found {segment.count(target)}")
        replacement = '"accepted": [' + json.dumps(answer, ensure_ascii=False) + ']'
        text = text[:start] + segment.replace(target, replacement) + text[start + len(segment):]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--answers", help="JSON {activityId: answer} to check (and apply)")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    proposed = json.load(open(a.answers, encoding="utf-8")) if a.answers else {}

    problems, checked, applied, unknown = [], 0, 0, set(proposed)
    for level, path in BUNDLES.items():
        bundle = json.load(open(path, encoding="utf-8"))
        for t in tasks(bundle):
            answers = list(t.get("accepted") or [])
            if t["id"] in proposed:
                unknown.discard(t["id"])
                if not answers:
                    answers = [proposed[t["id"]]]
                    if a.apply:
                        t["accepted"] = answers
                        applied += 1
            if not answers:
                problems.append(f"{t['id']}: no model answer")
                continue
            for ans in answers:
                checked += 1
                ok, matched = passes(ans, t["evaluation"])
                if not ok:
                    problems.append(f"{t['id']}: {matched}/{t['evaluation']['minGroupsMatched']} groups: {ans!r}")
                wg = t.get("wordGuide")
                if t["type"] == "write" and wg and len(wg) == 2:
                    n = len(ans.split())
                    if not wg[0] <= n <= wg[1]:
                        problems.append(f"{t['id']}: {n} words, guide {wg}: {ans[:50]!r}")
        if a.apply and applied:
            apply_textually(path, {t["id"]: t["accepted"][0] for t in tasks(bundle)
                                   if t["id"] in proposed and t["accepted"] == [proposed[t["id"]]]})
    for p in problems:
        print(p)
    if unknown:
        print("answers for unknown or non-keyword tasks:", ", ".join(sorted(unknown)))
    print(f"{checked} model answers checked, {len(problems)} problems" + (f", {applied} applied" if a.apply else ""))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
