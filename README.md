# Mohingo

Offline-first, bilingual (Arabic/English) CEFR English-learning app for self-directed adult Arabic-speaking learners — two complete CEFR levels, A1 and A2 (see [CLAUDE.md](CLAUDE.md) for exact status, and "Known limitations" below for what "complete" does and doesn't cover).

Full documentation — product scope, architecture, data model, and every other project decision — lives in [`docs/`](docs/), starting from [CLAUDE.md](CLAUDE.md). This file is a practical setup/build/troubleshooting guide, not a decision record — if something here and a doc in `docs/` disagree, `docs/` is the source of truth.

## Prerequisites

- Flutter SDK (stable channel; this project was built against Flutter 3.47.2 / Dart 3.13.2 — see `environment.sdk` in `pubspec.yaml` for the minimum supported Dart version)
- No Firebase project, no API keys, no account of any kind — v1 is fully local and offline (see [ADR 0004](docs/adr/0004-local-only-v1-no-firebase-backend.md)). `flutter pub get` and `flutter run` work with zero external setup.
- Python 3.11+ **only if you regenerate speech audio** — every spoken string ships as a pre-generated clip ([ADR 0008](docs/adr/0008-bundled-pre-generated-speech-audio.md)); the clips are committed, so building and running the app needs no Python. Setup for the tool is in [tool/audio/README.md](tool/audio/README.md).
- Android: no separate Android SDK setup beyond what `flutter doctor` already checks for.
- iOS: a Mac with Xcode is required to build/run the iOS target — not available in every dev environment (this project has been built and tested on Windows without one; iOS-specific configuration like `Info.plist` has been hand-edited and verified by reading the file, not by an actual Xcode build).

## Setup

```
flutter pub get
```

No `.env` file, no secrets, no config to fill in. The curriculum content is already committed as bundled assets — one file per released level (`assets/content/en/A1/a1-course-bundle.json`, `assets/content/en/A2/a2-course-bundle.json`). Those files are the source of truth for content: edit them directly, not the `reference/` packages they came from (each has an `OUT_OF_DATE.md` explaining why), and keep `test/content/` green — see [docs/TESTING.md](docs/TESTING.md). Every string those bundles speak also ships as an audio clip under `assets/audio/en/<LEVEL>/` (about 50 MB for A1 and A2 together); after editing a spoken string, regenerate that level's clips with `python tool/audio/generate_audio.py --level A1 --prune`, or `test/content/levels/level_audio_test.dart` will tell you to.

## Common commands

```
flutter pub get                                              # install dependencies
dart run build_runner build --delete-conflicting-outputs     # regenerate Drift/Riverpod code — see "When to run codegen" below
flutter gen-l10n                                              # regenerate AppLocalizations after editing lib/l10n/*.arb
dart format --set-exit-if-changed .                           # format check (also just `dart format .` to apply)
flutter analyze                                               # static analysis — must report "No issues found!"
flutter test                                                  # the full test suite (unit + widget)
dart run tool/update_published_ids.dart                       # after ADDING curriculum content — records its ids, then commit the diff
python tool/audio/generate_audio.py --level A1 --prune       # after EDITING any spoken bundle string — regenerates that level's clips (tool/audio/README.md)
flutter run                                                   # run on a connected device/emulator
```

### When to run codegen

`dart run build_runner build --delete-conflicting-outputs` regenerates two families of generated files:

- **Drift** (`*.g.dart` next to `lib/data/local/database.dart`) — after adding/editing a table in `lib/data/local/tables/`.
- **Riverpod** (`*.g.dart` next to any file with a `@riverpod`/`@Riverpod(...)`-annotated provider) — after adding/editing a codegen provider.

Note: `riverpod_generator` (as resolved in this project) throws `InvalidTypeException` on a provider whose return type is a Drift-generated `DataClass` directly (e.g. a raw `Learner` or `UnitProgressData`) — those providers are hand-written plain `FutureProvider`s instead of `@riverpod`-annotated, by design; see [TECH_STACK.md](docs/TECH_STACK.md). Don't try to "fix" this by adding `@riverpod` to them.

After editing `lib/l10n/app_en.arb` or `lib/l10n/app_ar.arb`, run `flutter gen-l10n` (not `build_runner`) to regenerate `lib/core/l10n/generated/`.

## Running tests

```
flutter test                      # unit + widget tests (879 passing as of the last full run — see CLAUDE.md)
flutter test integration_test/    # not yet added — see "Known limitations" below
```

To run a single file or filter by test name:

```
flutter test test/features/placement_test/placement_classifier_test.dart
flutter test --plain-name "some substring of a test description"
```

A widget test that reads the database after `_pumpAppAndWaitForContent` returns will hang, not fail. `flutter test` runs widget tests under a fake clock, so real async work — a Drift query, anything a provider kicked off — cannot complete outside `tester.runAsync`, and a poll loop placed after the pump waits forever (observed: a 10-minute timeout). Do the read *inside* the helper's own `runAsync` loop, which is what its `onEachPump`/`until` parameters are for.

If a widget test hangs or times out otherwise, it's almost always a missing fake-service override — see `test/features/speech/fake_speech_services.dart` and how existing tests use it. Real device-backed plugins (`flutter_tts`, `speech_to_text`, `permission_handler`) have no platform channel to answer in `flutter test`, so any widget that reads their providers needs `textToSpeechServiceProvider`/`speechCapabilityServiceProvider` overridden with a fake, or the test will hang waiting for a response that never comes.

## Known limitations (honestly, not swept under the rug)

- **No real Android/iOS device or emulator has been used to build or run this app** in the environment this was developed in. Every device-dependent guarantee (speech permission flows, playback of the bundled speech clips through `audioplayers`, the device TTS/STT fallbacks, actual frame performance, real app-store build signing) is verified as far as it can be without one — see [TESTING.md](docs/TESTING.md) and [TECH_STACK.md](docs/TECH_STACK.md) for exactly what that means per area — and flagged as unverified where it can't be. Building and running on a real device is the natural next step before any store submission.
- **The bundled voices have been checked by machine, not yet by ear across the whole course.** Every clip was generated by Kokoro-82M and a transcription check flags clips whose words drift from their text, but whether a name is pronounced well is a human judgement; the owner listened to the first A1 lessons only. Known and accepted: A2's two-person listening transcripts carry no speaker labels, so they play in the teacher's single voice until the content marks its turns (see [ROADMAP.md](docs/ROADMAP.md)).
- **No `integration_test/` suite exists yet** — end-to-end flows are covered by widget tests that drive real content through real widgets (e.g. `test/features/lesson_player/lesson_player_e2e_test.dart`), which is a genuinely strong substitute for logic correctness but isn't the same as a real on-device integration test.
- **No CI/CD is configured** — see [ROADMAP.md](docs/ROADMAP.md).
- **Release builds sign with the debug key** on Android (`android/app/build.gradle.kts`) — a real signing config is needed before any Play Store upload.
- **App icons are still the default Flutter template icons** on both platforms — no branded icon has been designed yet.
- **A2's Arabic was read and confirmed on 2026-09-21** by the project's Arabic-speaking owner, closing what had been this level's one unclosed quality gap. Worth keeping in mind for B1: the gates can prove a field contains Arabic script and is not the English copied across, and that is all they can prove. Whether a line reads naturally, whether the register fits, whether a rendering is idiomatic rather than merely correct — none of that is machine-checkable, and the project's rule is that each language is written natively rather than translated from the other ([docs/UX_PRINCIPLES.md](docs/UX_PRINCIPLES.md)). Every level still needs a human read before it ships.
- **App-store data-safety/privacy-label declarations and a privacy-policy update have not been addressed** for the app's first third-party network transmission: an open-ended **typed** answer on a rubric marked `onlineRefinement` may be sent to the free public LanguageTool API for a grammar-quality check (always optional — a bounded local-only fallback grades it if the device is never online; see [ADR 0005](docs/adr/0005-narrow-network-exception-for-open-ended-grading.md)). The scope, counted: **59 rubrics across both released levels — 23 in A1's units, 36 in A2's — every one of them a `write` task, none in either level's capstones.** Nothing a learner *says* takes that path; A2's authoring briefly marked 120 speaking tasks, commit `1893e23` unmarked them before release, and `test/content/online_refinement_boundary_test.dart` now fails if one comes back. Google Play Data Safety and Apple Privacy Nutrition Label entries, and whatever privacy-policy text they require, still need to be decided and written before any store submission.

## Project structure

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full folder-structure rationale. Short version: `lib/content/` is the read-only curriculum bundle layer, `lib/data/local/` is the Drift progress database, `lib/features/<feature>/` follows a `presentation → domain → data` layering per feature, and `lib/core/` holds cross-cutting app-shell/theme/router/l10n code.

## Contributing / conventions

See [docs/CONVENTIONS.md](docs/CONVENTIONS.md) for naming, structure, and commit/branch rules, and [CLAUDE.md](CLAUDE.md)'s "Definition of done" table for which doc to update when a given kind of change lands.
