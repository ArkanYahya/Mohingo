# Tech Stack

Flutter (Dart SDK `^3.13.2`), Material 3, `go_router`, `flutter_riverpod` v3 (+ `riverpod_annotation`/`riverpod_generator` codegen), Drift/SQLite (local progress DB only — bundled curriculum content is a separate, never-mirrored-into-Drift in-memory store, see `mem:core` → ARCHITECTURE.md).

Full rationale/versions live in docs/TECH_STACK.md — bump its "Last verified" line in the same change whenever a dependency is added/removed/changed.

Notable libs and why: `flutter_tts` + `speech_to_text` + `permission_handler` (on-device speech only, no cloud STT/TTS), `audioplayers` (short local sound-effect assets only), `connectivity_plus` (gates the one deferred online-refinement queue drain), `http` (LanguageTool grammar-check calls — the only outbound network call in the whole app, and it's optional/best-effort).

Gotchas:
- `riverpod_generator` fails (`InvalidTypeException`) on a provider returning a Drift `DataClass` type directly — use a plain, non-codegen `FutureProvider`/`FutureProvider.family` instead (see `currentLearnerProvider`, `lessonReviewAttemptsProvider` for the established pattern).
- `permission_handler_android` is pinned to `13.0.1` via `dependency_overrides` in pubspec.yaml — `14.0.0` requires Android SDK 37, which isn't a resolvable Gradle platform yet.
- After editing a Drift table or an `@riverpod`-annotated provider: `dart run build_runner build --delete-conflicting-outputs`.
