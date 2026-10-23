> **What this file is:** The boring-but-expensive-if-inconsistent rules — naming, file layout, error handling shape, commit/branch format. The stuff that's cheap to follow if written down and expensive to reconcile if not.
> **How to use it:** Follow as default behavior in every session, no exceptions unless the code being touched already established a different local pattern (match it, then flag the inconsistency here).

_Last verified: 2026-10-22 (`ccr-3aef6bc0-xt12aw`) — a second Python tool, `tool/meaning/` (model answers and the bundled embedding model, [ADR 0013](adr/0013-on-device-ai-for-free-answers.md)), and `tool/audio/sync_manifest_version.py` for a content change that touches no spoken string. Previously verified 2026-09-24 (`release/v1.0.0`) — `tool/ios_launch_image.swift` (Swift, macOS AppKit) renders the iOS launch image. Previously verified 2026-09-23 (`release/v1.0.0`) — `tool/legal/` joins `tool/audio/` as a Python tool, standard library only ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)). Previously verified 2026-09-23 (`release/v1.0.0`) — Versioning: the version is set only in `pubspec.yaml` and read at runtime; the agreement and app-guide versions are separate constants ([ADR 0011](adr/0011-first-run-agreement-app-guide-and-account-deletion.md)). Previously verified 2026-09-22 (`feature/bundled-audio`) — `tool/` may hold a Python tool: `tool/audio/` generates the bundled speech clips, with its own `requirements.txt` and tests, and nothing under it ships ([ADR 0008](adr/0008-bundled-pre-generated-speech-audio.md)). Previously verified 2026-09-21 (`feature/level-standard-and-content-versioning`) — added "Content ids, after a level ships": ids are permanent, an activity's `mode` is frozen and its `canDo` is append-only once a level is published, with what each one does to a learner who has already studied it, and the `contentVersion` bump a content change must carry. All of it was previously a comment in one table file. Previously verified: 2026-09-19 — added Versioning (`kAppVersion` kept in step with pubspec.yaml). Previously verified 2026-09-01 — initial conventions established via brainstorming session._

# Conventions

## Naming

- Files: `snake_case.dart` (standard Dart convention)
- Variables/functions: `lowerCamelCase`
- Components/classes (widgets, providers, models): `UpperCamelCase`
- Firestore fields / Drift columns: `lowerCamelCase`, matching the Dart model field names exactly (see [DATA_MODEL.md](DATA_MODEL.md)) — no snake_case in data payloads, to avoid a mapping layer

## File & module organization

Feature-first, per [ARCHITECTURE.md](ARCHITECTURE.md)'s folder structure: new code lives under `lib/features/<feature>/{presentation,application,domain,data}`; shared/cross-feature code goes in `lib/core/`; local/remote data access code goes in `lib/data/`. Dev-time tools live in `tool/`: Dart scripts run with `dart run tool/<name>.dart`; `tool/audio/` is Python because the speech engine is a Python library — it keeps its own `requirements.txt`, its tests in `tool/audio/tests/` (pytest), its downloaded models gitignored under `tool/audio/models/`, and nothing under it is imported by the app. `tool/ios_launch_image.swift` is Swift because it draws with macOS's AppKit (the iOS launch image; docs/DESIGN_SYSTEM.md, Launch screen). `tool/legal/` is Python too, standard library only, so it needs no environment: it renders the public web pages ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)), and its tests run with `python3 -m unittest tool/legal/test_build_site.py`. `tool/meaning/` is Python for the same reason (ONNX quantisation and the reference tokenizer); it checks model answers and rebuilds `assets/models/`, and nothing under it ships either.

## Error handling

- Pattern: typed exceptions (e.g. `SyncException`, `PlacementTestException`) thrown from the repository layer, caught at the UI/state (Riverpod) layer — no Result/Either type, kept plain since this is a solo project and Dart's exception handling is sufficient.
- Errors are translated to user-facing messages only at the UI layer, following the rules in [UX_PRINCIPLES.md](UX_PRINCIPLES.md) — never surface a raw exception message to the learner.

## Code style

- Formatter/linter: `dart format` + `flutter_lints` (standard Flutter analysis rules).
- No additional rules beyond the linter defaults for now.

## Git

- Branch naming: `feature/<short-desc>`, `fix/<short-desc>` — optional, since this is a solo project (direct commits to `main` are also fine for small changes).
- Commit message format: short imperative summary line (e.g. "Add unit progress gating"); no strict conventional-commits requirement.
- PR requirements: none — solo project, no review process. (Revisit if a second contributor joins.)

## Content ids, after a level ships

**Once a level is published, its ids are permanent, an activity's `mode` is frozen, and its `canDo` list is append-only.**

`activity_attempts` stores `activityId`, `lessonId`, `mode` and `canDoId` as plain bundle strings with no foreign key (see [DATA_MODEL.md](DATA_MODEL.md)), so a learner's recorded evidence outlives the content it points at. Each rule has a consequence for a real learner:

- **Reuse an id** and their work on the old activity is re-attributed to the new one.
- **Change a published `mode`** and every stored attempt on it is re-counted — a `practice`→`mastery` re-tag hands them evidence they never earned, and the reverse takes away mastery they did.
- **Drop a published `canDo`** and their stored evidence names an objective the unit no longer requires; a unit they had mastered stops being mastered.

Retiring content therefore means leaving the id in place, or giving the replacement a new one — never deleting or re-pointing the old. A genuinely deliberate removal means hand-editing `test/content/published/<level>-published-ids.json`, which is a visible act a reviewer can question.

**A content change that touches no spoken string still bumps `contentVersion`, and then the audio manifest must follow:** `python tool/audio/sync_manifest_version.py --level A1` verifies every spoken string already has its clip and stamps the manifest with the new version, without the engine. If anything spoken did change it refuses, and `generate_audio.py` is the way.

**A content change must bump the bundle's `contentVersion`.** The app treats an unchanged `contentVersion` as "not an upgrade" and skips the content diff entirely, so a change that keeps the old string is invisible to stale detection on every device (see [DATA_MODEL.md](DATA_MODEL.md)'s `content_versions`).

Enforced by `test/content/published_id_stability_test.dart` against a committed snapshot per level. After **adding** content:

```
dart run tool/update_published_ids.dart
```

and commit the diff. The script merges rather than regenerates — it refuses to drop an id, change a mode, drop a tag, or record new ids under an unchanged `contentVersion` — so making the gate green by re-running it is not a move that exists.

## Versioning

The app version lives only in `pubspec.yaml` (`version: 1.0.0+1` — name + build number; raise the build number for every store upload). About reads it from the installed package (`appPackageInfoProvider`), so there is no second copy. Two other versions are independent of it: `kAgreementVersion` (raise only when the privacy policy or terms change materially — learners must accept again) and `kAppGuideVersion` (raise when the guide should run once more for everyone).

## Dependencies

- No formal approval process (solo project) — but check [TECH_STACK.md](TECH_STACK.md) before adding a new library or service, and update it in the same change if the addition sticks (per the root [CLAUDE.md](../CLAUDE.md) definition of done). Keep the dependency footprint minimal given the offline-first, no-backend constraint.
