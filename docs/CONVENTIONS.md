> **What this file is:** The boring-but-expensive-if-inconsistent rules — naming, file layout, error handling shape, commit/branch format. The stuff that's cheap to follow if written down and expensive to reconcile if not.
> **How to use it:** Follow as default behavior in every session, no exceptions unless the code being touched already established a different local pattern (match it, then flag the inconsistency here).

_Last verified: 2026-09-19 — added Versioning (`kAppVersion` kept in step with pubspec.yaml). Previously verified 2026-09-01 — initial conventions established via brainstorming session._

# Conventions

## Naming

- Files: `snake_case.dart` (standard Dart convention)
- Variables/functions: `lowerCamelCase`
- Components/classes (widgets, providers, models): `UpperCamelCase`
- Firestore fields / Drift columns: `lowerCamelCase`, matching the Dart model field names exactly (see [DATA_MODEL.md](DATA_MODEL.md)) — no snake_case in data payloads, to avoid a mapping layer

## File & module organization

Feature-first, per [ARCHITECTURE.md](ARCHITECTURE.md)'s folder structure: new code lives under `lib/features/<feature>/{presentation,application,domain,data}`; shared/cross-feature code goes in `lib/core/`; local/remote data access code goes in `lib/data/`.

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

## Versioning

The app version lives in `pubspec.yaml` and is shown in Settings from `kAppVersion` (`lib/core/app_version.dart`). Bump both together — `test/core/app_version_test.dart` fails if they differ.

## Dependencies

- No formal approval process (solo project) — but check [TECH_STACK.md](TECH_STACK.md) before adding a new library or service, and update it in the same change if the addition sticks (per the root [CLAUDE.md](../CLAUDE.md) definition of done). Keep the dependency footprint minimal given the offline-first, no-backend constraint.
