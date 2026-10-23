# Mohingo

Offline-first, bilingual (Arabic/English) CEFR English-learning app for self-directed adult Arabic-speaking learners — two complete CEFR levels, A1 and A2 (see [CLAUDE.md](CLAUDE.md) for exact status, and "Known limitations" below for what "complete" does and doesn't cover).

Full documentation — product scope, architecture, data model, and every other project decision — lives in [`docs/`](docs/), starting from [CLAUDE.md](CLAUDE.md). This file is a practical setup/build/troubleshooting guide, not a decision record — if something here and a doc in `docs/` disagree, `docs/` is the source of truth.

## Prerequisites

- Flutter SDK (stable channel; this project was built against Flutter 3.47.2 / Dart 3.13.2 — see `environment.sdk` in `pubspec.yaml` for the minimum supported Dart version)
- No Firebase project is needed to build or run: until the project is connected (`flutterfire configure`, [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)), the app runs local-only and Settings offers no sign-in. With the project connected, learners can optionally sign in and sync progress across devices ([ADR 0010](docs/adr/0010-optional-accounts-and-progress-sync.md)).
- Node.js 18+ and Java 11+ **only to test the Firestore Security Rules** (`tool/firestore_rules_test/`).
- Python 3.11+ **only for the dev-time tools**: regenerating speech audio (`tool/audio/`), and checking model answers or rebuilding the bundled embedding model (`tool/meaning/`, `pip install onnx onnxruntime`). The model is committed ([ADR 0013](docs/adr/0013-on-device-ai-for-free-answers.md)), so building and running the app needs no Python.
- Python 3.11+ **only if you regenerate speech audio** — every spoken string ships as a pre-generated clip ([ADR 0008](docs/adr/0008-bundled-pre-generated-speech-audio.md)); the clips are committed, so building and running the app needs no Python. Setup for the tool is in [tool/audio/README.md](tool/audio/README.md).
- Android: no separate Android SDK setup beyond what `flutter doctor` already checks for.
- iOS: minimum iOS **16.0** (`flutter_onnxruntime` needs it; raised from 15.0 on 2026-10-23). A Mac with Xcode is required to build/run the iOS target — not available in every dev environment (this project has been built and tested on Windows without one; iOS-specific configuration like `Info.plist` has been hand-edited and verified by reading the file, not by an actual Xcode build).

## Setup

```
flutter pub get
```

No `.env` file and no secrets. The Firebase client configuration (`lib/firebase_options.dart`, `android/app/google-services.json`) is committed once the project is connected — it identifies the project and is not a secret ([docs/SECURITY.md](docs/SECURITY.md)). The curriculum content is already committed as bundled assets — one file per released level (`assets/content/en/A1/a1-course-bundle.json`, `assets/content/en/A2/a2-course-bundle.json`). Those files are the source of truth for content: edit them directly, not the `reference/` packages they came from (each has an `OUT_OF_DATE.md` explaining why), and keep `test/content/` green — see [docs/TESTING.md](docs/TESTING.md). Every string those bundles speak also ships as an audio clip under `assets/audio/en/<LEVEL>/` (about 50 MB for A1 and A2 together); after editing a spoken string, regenerate that level's clips with `python tool/audio/generate_audio.py --level A1 --prune`, or `test/content/levels/level_audio_test.dart` will tell you to.

## Common commands

```
flutter pub get                                              # install dependencies
dart run build_runner build --delete-conflicting-outputs     # regenerate Drift/Riverpod code — see "When to run codegen" below
flutter gen-l10n                                              # regenerate AppLocalizations after editing lib/l10n/*.arb
dart format --set-exit-if-changed .                           # format check (also just `dart format .` to apply)
flutter analyze                                               # static analysis — must report "No issues found!"
flutter test                                                  # the full test suite (unit + widget)
(cd tool/firestore_rules_test && npm install && npm test)     # Firestore Security Rules, on the emulator
dart run tool/update_published_ids.dart                       # after ADDING curriculum content — records its ids, then commit the diff
python tool/audio/generate_audio.py --level A1 --prune       # after EDITING any spoken bundle string — regenerates that level's clips (tool/audio/README.md)
python tool/audio/sync_manifest_version.py --level A1        # after a content change that touched NO spoken string — stamps the manifest with the new contentVersion
python tool/meaning/check_model_answers.py                   # every keyword-graded mastery speak/write task has a model answer that passes its rubric (tool/meaning/README.md)
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
flutter test                      # unit + widget tests (1043 passing as of the last full run)
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

- **Accounts and sync have been tested against a simulated cloud and the Firestore emulator, not yet on real devices against the real project.** The sync engine, merge rules, reset, account switching and migration run in `flutter test` over real SQLite with an in-memory cloud; the Security Rules run on the Firestore emulator. The Firebase adapters themselves (`FirebaseAuthRepository`, `FirestoreProgressStore`) and Google sign-in need a device and the connected project — see [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) "Verifying end to end". No APK was built in the development environment (its network policy blocks the Android SDK download).
- **iOS builds and is connected to Firebase, but has not run on an iPhone.** Sign in with Apple, Apple token revocation on account deletion, the entitlement, the Arabic permission prompts, the iOS Firebase app and the Google URL scheme are in place ([ADR 0012](docs/adr/0012-ios-release-sign-in-with-apple.md)). The Apple provider and its revocation key are not yet set up in Firebase, and the app has not yet been signed or run on an iPhone. An unsigned release build (`flutter build ios --no-codesign`) compiles on the development Mac, an Intel MacBook Pro, with Xcode 26.6's Universal build (2026-09-24; Xcode 27 runs only on Apple silicon). The first build takes about 12 minutes there, most of it compiling the Firebase SDK. See "Releasing (iOS)" below. An account made with Sign in with Apple can't sign in on Android yet.

- **The on-device meaning signal has never run on a phone.** The bundled embedding model ([ADR 0013](docs/adr/0013-on-device-ai-for-free-answers.md)) was exercised in Python on this machine and the Dart service only as far as `flutter test` allows, where the ONNX runtime has no platform and the service correctly falls back to "no signal" — which means the whole suite is green with the signal doing nothing. The first real run must check that `flutter_onnxruntime` builds (it fetches ONNX Runtime from Maven and CocoaPods at build time), that the session loads from the asset, and the time per answer. The AI pack (Phase B) is not built; Settings shows its row as Coming soon.
- **No real Android/iOS device or emulator has been used to build or run this app** in the environment this was developed in. Every device-dependent guarantee (speech permission flows, playback of the bundled speech clips through `audioplayers`, the device TTS/STT fallbacks, actual frame performance, real app-store build signing) is verified as far as it can be without one — see [TESTING.md](docs/TESTING.md) and [TECH_STACK.md](docs/TECH_STACK.md) for exactly what that means per area — and flagged as unverified where it can't be. Building and running on a real device is the natural next step before any store submission.
- **The bundled voices have been checked by machine, not yet by ear across the whole course.** Every clip was generated by Kokoro-82M and a transcription check flags clips whose words drift from their text, but whether a name is pronounced well is a human judgement; the owner listened to the first A1 lessons only. Known and accepted: A2's two-person listening transcripts carry no speaker labels, so they play in the teacher's single voice until the content marks its turns (see [ROADMAP.md](docs/ROADMAP.md)).
- **No `integration_test/` suite exists yet** — end-to-end flows are covered by widget tests that drive real content through real widgets (e.g. `test/features/lesson_player/lesson_player_e2e_test.dart`), which is a genuinely strong substitute for logic correctness but isn't the same as a real on-device integration test.
- **Release builds shrink with R8**, and ONNX Runtime needs `android/app/proguard-rules.pro`'s keep rule to survive it; the first APK on a phone exited on the first Check for that reason (2026-10-23). If a release build ever exits on Check again, `adb logcat` at the moment of the crash is what tells the cause — a debug build (`flutter build apk --debug`) does not shrink and will not reproduce it.
- **The CI APK is a universal build of about 130 MB** (three ABIs, 55 MB of speech clips, a 23 MB model). Fine for trying it on a phone; a store release would ship an app bundle with per-ABI splits, which is part of the release work still owed in [ROADMAP.md](docs/ROADMAP.md).
- **CI builds, but does not release.** GitHub Actions runs the checks and produces an Android APK and an unsigned iOS build on every push (below); nothing signs with a release key or uploads to a store — see [ROADMAP.md](docs/ROADMAP.md).
- **Release signing needs your upload key.** `android/app/build.gradle.kts` signs with `android/key.properties` when it exists and falls back to the debug key (with a build warning) when it does not — see "Releasing" below.
- **The branded app icon has not been seen on a real launcher yet.** It is generated for both platforms from `assets/icon/` (see [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md), App icon), and the Android adaptive version was checked against circle and rounded-square masks as images only.
- **A2's Arabic was read and confirmed on 2026-09-21** by the project's Arabic-speaking owner, closing what had been this level's one unclosed quality gap. Worth keeping in mind for B1: the gates can prove a field contains Arabic script and is not the English copied across, and that is all they can prove. Whether a line reads naturally, whether the register fits, whether a rendering is idiomatic rather than merely correct — none of that is machine-checkable, and the project's rule is that each language is written natively rather than translated from the other ([docs/UX_PRINCIPLES.md](docs/UX_PRINCIPLES.md)). Every level still needs a human read before it ships.
- **Store declarations are still to be filed.** What leaves the device is now written down in the in-app Privacy Policy (`assets/legal/privacy_en.md` / `privacy_ar.md`): account data and progress to Firebase when signed in, the text of typed answers on the 59 `onlineRefinement` writing rubrics to LanguageTool when online, and audio to the phone's own speech recogniser. Google Play Data Safety / Apple privacy labels must match it, and the policy must be at a public URL for the store listings. It is: `https://mohingo.web.app/privacy`, with the support page at `https://mohingo.web.app/` and account deletion at `/delete-account`. Redeploy after any change to `assets/legal/` ([FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md), Public pages).

## Releasing (Android)

1. Create an upload keystore once (keep it and its passwords safe, outside the repository):
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` (git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/path/to/upload-keystore.jks
   ```
3. Raise the build number in `pubspec.yaml` (`version: 1.0.0+N`) for every upload.
4. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
5. Add the upload key's and Play App Signing key's SHA-1/SHA-256 to the Firebase Android app, then download the new `google-services.json` — otherwise Google sign-in fails in the release build.

## Releasing (iOS)

1. **A Mac that can upload.** Since 28 April 2026 the App Store accepts only builds made with Xcode 26 or later. Xcode 27, which the Mac App Store now offers, runs only on Apple silicon. An **Intel Mac** needs Xcode 26.x instead, in its **Universal** build (not the Apple silicon one) from [developer.apple.com/download/all](https://developer.apple.com/download/all/) — free with any Apple ID. Xcode 26.4 and later need macOS Tahoe 26.2+, and 26.0-26.3 need macOS Sequoia 15.6+. Unpack the `.xip` into `/Applications`, then `sudo xcode-select -s /Applications/Xcode.app`, `sudo xcodebuild -license accept`, `xcodebuild -runFirstLaunch` and `xcodebuild -downloadPlatform iOS`. When Apple next raises the minimum to the iOS 27 SDK (the last several minimums took effect each April), an Intel Mac can no longer make an upload. From then on, build in the cloud on an Apple silicon Mac instead: Codemagic's free plan gives a personal account 500 macOS minutes a month.
2. **Apple Developer Program** membership ($99 a year). In Xcode → Settings → Accounts, add the Apple ID. Open `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → choose the **Team**. Automatic signing registers `com.northstorm.mohingo` with Sign in with Apple, from `Runner.entitlements`.
3. **Firebase for iOS**: steps 1-4 of [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md), iOS: register the app, add the Google URL scheme, enable Apple, and give Firebase the Apple key for token revocation.
4. **Run it on an iPhone** before anything else: `flutter run --release`. Check email, Google and Apple sign-in, deleting an Apple account, a speaking task's microphone and speech prompts (in Arabic too, with the phone set to Arabic), and lesson audio.
5. **Build and upload.** Raise `version: 1.0.0+N` in `pubspec.yaml` for every upload, then run `flutter build ipa --release`, which writes `build/ios/ipa/*.ipa`. Upload it with Apple's **Transporter** app, or open `build/ios/archive/Runner.xcarchive` in Xcode → Organizer → Distribute App.
6. **App Store Connect**: every answer it asks for (the app record, listing text in English and Arabic, screenshots, App Privacy, age rating, review notes) is in [docs/STORE_LISTING.md](docs/STORE_LISTING.md). The app is iPhone only (`TARGETED_DEVICE_FAMILY = 1`), so only 6.9-inch iPhone screenshots are needed. Test through TestFlight, then submit for review.

## Trying a build on a phone

Every push runs `.github/workflows/ci.yml`, which builds a release APK. To put it on an Android phone: open the repository's **Actions** tab, pick the run for your commit, download the artifact **mohingo-android-apk**, unzip it, copy `app-release.apk` to the phone and open it (allow installing from this source when asked). The APK is signed with the runner's debug key, which changes every run, so **uninstall the previous Mohingo build first** or Android refuses the install. The iOS job only proves the project compiles; installing on an iPhone needs an Apple developer account and a Mac.

Things worth checking on the first device run, none of which this environment could: that speech clips play and the microphone flow works; that a writing or speaking task with a model answer grades without a visible pause (the meaning signal, [ADR 0013](docs/adr/0013-on-device-ai-for-free-answers.md) — `flutter logs` prints `meaning signal model unavailable: …` if the model failed to load, and nothing if it loaded); frame smoothness on the longest lists; and, with the Firebase project connected, sign-in and sync ([docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)).

## Project structure

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full folder-structure rationale. Short version: `lib/content/` is the read-only curriculum bundle layer, `lib/data/local/` is the Drift progress database, `lib/features/<feature>/` follows a `presentation → domain → data` layering per feature, and `lib/core/` holds cross-cutting app-shell/theme/router/l10n code.

## Contributing / conventions

See [docs/CONVENTIONS.md](docs/CONVENTIONS.md) for naming, structure, and commit/branch rules, and [CLAUDE.md](CLAUDE.md)'s "Definition of done" table for which doc to update when a given kind of change lands.
