> **What this file is:** How this repository is connected to its Firebase project, and how to redo it — for a new machine, a new developer, or a new platform. The design is [ADR 0010](adr/0010-optional-accounts-and-progress-sync.md); the data contract is [API_CONTRACT.md](API_CONTRACT.md).
> **How to use it:** Follow the steps in order. Anything that needs the project owner's Google account is marked **(console)** or **(your machine)**; everything else is already in the repository.

_Last verified: 2026-09-24 (`release/v1.0.0`) — **One app id, `com.northstorm.mohingo`, on both platforms** ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)): Android app `1:219416710516:android:6a72382d69964d7abd3021` and iOS app `1:219416710516:ios:52f73b11cfb2eddbbd3021`; the Android app carries the owner's debug SHA-1s (including the Mac's, `4945f2d4…`) and SHA-256s. The earlier `com.mohingo.mohingo` registrations (`…android:484ea34d5b308574bd3021`, `…ios:e5a916eebbf91de0bd3021`) were removed the same day; Firebase can restore them until 2026-10-24. Earlier the same day — **iOS app registered and pages live**: iOS app `1:219416710516:ios:52f73b11cfb2eddbbd3021`, bundle id **`com.northstorm.mohingo`** (Apple had `com.mohingo.mohingo` taken, so iOS differs from the Android package, which stays `com.mohingo.mohingo`; the first iOS registration, `…ios:e5a916eebbf91de0bd3021` for `com.mohingo.mohingo`, is unused), `GoogleService-Info.plist` and the Google URL scheme committed (iOS steps 1-2 done; 3-5 not yet); the public pages are deployed at `https://mohingo.web.app`. Previously verified 2026-09-23 (`release/v1.0.0`) — **iOS and the public pages** ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)): the iOS section below is now the real procedure (register the app, Google URL scheme, Apple provider with its key for token revocation), and "Public pages" deploys the support, privacy, terms and delete-account pages to Firebase Hosting. Neither has been run yet. Previously verified 2026-09-23 (`claude/firebase-auth-sync-ji1cww`) — the project is connected: **`mohingo`**, Android app `1:219416710516:android:484ea34d5b308574bd3021`, Email/Password and Google enabled, Firestore `(default)` in **`me-central2` (Dammam)**, rules and indexes deployed, the owner's debug SHA-1/SHA-256 registered. Steps 1-6 below are done; step 7 and iOS are not._

# Firebase setup

## What's already in the repository

- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` (`pubspec.yaml`).
- `lib/main.dart` starts Firebase from `lib/firebase_options.dart`. Until `flutterfire configure` has run, that file is a **placeholder** that throws; the app catches it and runs local-only (no sign-in offered). Every learning feature works either way.
- `firestore.rules`, `firestore.indexes.json` (empty — no composite index is needed), `firebase.json` (rules, indexes, hosting, emulator ports).
- `tool/legal/` — builds the public web pages (see "Public pages" below).
- `tool/firestore_rules_test/` — rules tests against the emulator.

## One-time setup (Android)

Tools, on your machine: Node.js 18+, Java 17+ (emulator only), Flutter.

```sh
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login                          # (your machine) opens a browser
```

1. **Create the project** (console): <https://console.firebase.google.com> → Add project. Google Analytics is not needed.
2. **Connect the app** (your machine), from the repository root:
   ```sh
   flutterfire configure --project=<your-project-id> --platforms=android \
     --android-package-name=com.northstorm.mohingo
   ```
   This registers the Android app, writes `lib/firebase_options.dart` and `android/app/google-services.json`, and adds the `com.google.gms.google-services` Gradle plugin. Commit all three.
3. **Enable sign-in providers** (console): Authentication → Get started → Sign-in method → enable **Email/Password**, then **Google** (choose a support email). Leave email-enumeration protection on (the default).
4. **Add SHA fingerprints for Google sign-in** (your machine + console):
   ```sh
   cd android && ./gradlew signingReport
   ```
   Copy the `SHA1` and `SHA-256` of the `debug` variant (and, once a release key exists, of `release`) into Project settings → Your apps → Android → Add fingerprint. Then **run step 2 again** so `google-services.json` contains the OAuth client that Google sign-in needs (`default_web_client_id`). Each machine's debug key is different: every developer who builds must add theirs.
5. **Create Firestore** (console): Firestore Database → Create database → **Production mode** → pick a location close to your learners (e.g. `eur3`/`europe-west` for the Middle East and North Africa; it can't be changed later).
6. **Deploy the rules** (your machine):
   ```sh
   firebase use --add <your-project-id>   # writes .firebaserc — commit it
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   Never leave the database in test mode: until this deploy, production mode denies everything, which is safe.
7. **Restrict the API key** (console, recommended): Google Cloud console → APIs & Services → Credentials → the Android key → restrict to Android apps with package `com.northstorm.mohingo` and your SHA-1s.

## Why these files are committed

`firebase_options.dart`, `google-services.json` and `.firebaserc` identify the project; they grant nothing on their own. Access to data is decided by Security Rules and sign-in. Keep real secrets — service-account keys, the LLM key of the authoring tool — out of the repository ([SECURITY.md](SECURITY.md)).

## Testing the rules

```sh
cd tool/firestore_rules_test
npm install
npm test        # starts the Firestore emulator, runs rules.test.js, stops it
```

## Verifying end to end

With two devices or emulators (A, B) on the same build:

1. On A: Settings → Account & sync → Sign in → Create an account. Finish a lesson.
2. Firebase console → Firestore → `users/<uid>/attempts` holds the answers.
3. On B: sign in with the same account → the lesson shows as done; Review holds the same words.
4. On B: finish another lesson. On A: bring the app to the foreground (or tap Sync now) → it appears.
5. Airplane mode on A: learn something → the account row says it will sync when back online. Turn it off → it syncs.
6. On A: sign out → guest progress only. Sign in as another account → none of the first account's progress.
7. Reset progress on A (signed in) → after B's next sync, B is reset too.
8. Rules: `npm test` above proves one account can't read another's data.

Developer logs: `flutter logs` and look for `mohingo.sync` (each run's outcome, counts, conflicts) and `mohingo.auth`. They never contain passwords, tokens, emails or answers.

## iOS

The code, the Sign in with Apple entitlement (`ios/Runner/Runner.entitlements`) and the Arabic permission prompts are in the repository ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)). What remains needs the owner's accounts. It needs a Mac with Xcode 26 or later: the App Store has refused builds from older Xcode versions since 28 April 2026. Xcode 27, which the Mac App Store now offers, runs only on Apple silicon. An **Intel Mac** needs Xcode 26.x instead, in its **Universal** build (not the Apple silicon one) from [developer.apple.com/download/all](https://developer.apple.com/download/all/) — free with any Apple ID. Xcode 26.4 and later need macOS Tahoe 26.2+, and 26.0-26.3 need macOS Sequoia 15.6+. See [README.md](../README.md), Releasing (iOS).

1. **Register the iOS app** (your machine), from the repository root:
   ```sh
   flutterfire configure --project=mohingo --platforms=android,ios \
     --android-package-name=com.northstorm.mohingo --ios-bundle-id=com.northstorm.mohingo
   ```
   This fills the iOS entry of `lib/firebase_options.dart` (including `iosClientId`, which Google sign-in reads) and writes `ios/Runner/GoogleService-Info.plist`. Commit both. If `iosClientId` is missing from the iOS options, Google was not enabled when the app was registered: check step 3 of the Android setup and run this again.
2. **Add the Google URL scheme** (your machine). Print the reversed client id:
   ```sh
   /usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist
   ```
   and paste it into `ios/Runner/Info.plist`, inside the top-level `<dict>`:
   ```xml
   <!-- Google sign-in returns to the app through this scheme: the
        REVERSED_CLIENT_ID of GoogleService-Info.plist. -->
   <key>CFBundleURLTypes</key>
   <array>
   	<dict>
   		<key>CFBundleURLSchemes</key>
   		<array>
   			<string>com.googleusercontent.apps.…</string>
   		</array>
   	</dict>
   </array>
   ```
   Without it, tapping "Continue with Google" crashes the app on iOS (the Google SDK throws when the scheme is missing). Done for the current iOS app; redo it only if the iOS app is registered again, since that changes the client id.
3. **Enable Apple sign-in** (console): Authentication → Sign-in method → Add new provider → **Apple** → Enable. That is enough for the native sign-in on iPhone.
4. **Let deletion revoke Apple tokens** (Apple Developer + console). Apple requires this when an Apple account is deleted ([ADR 0012](adr/0012-ios-release-sign-in-with-apple.md)):
   1. [developer.apple.com](https://developer.apple.com/account/resources) → Identifiers → **+** → **Services IDs** → e.g. `com.northstorm.mohingo.signin`, with Sign in with Apple enabled, primary App ID `com.northstorm.mohingo`, and return URL `https://mohingo.firebaseapp.com/__/auth/handler`.
   2. Keys → **+** → enable **Sign in with Apple**, configure it with the primary App ID (`com.northstorm.mohingo`) → download the `.p8` file (it can be downloaded only once) and note its **Key ID**.
   3. Firebase console → Authentication → Sign-in method → Apple → fill **Services ID**, **Apple team ID**, **Key ID** and the **private key** (the `.p8` contents). Save.

   Never commit the `.p8`: it is a secret ([SECURITY.md](SECURITY.md)). To check: sign in with Apple on an iPhone, delete the account in Settings → the app disappears from iOS Settings → your name → Sign in with Apple.
5. **Restrict the iOS API key** (console, recommended): as step 7 of the Android setup, restricted to iOS apps with bundle id `com.northstorm.mohingo`.

Then build and upload as [README.md](../README.md), "Releasing (iOS)", describes. Plugins come through Swift Package Manager, except `flutter_tts`, which has no Swift package yet and comes through CocoaPods (`ios/Podfile`). Commit `ios/Podfile.lock` and both `xcshareddata/swiftpm/Package.resolved` files: they pin every pod and Swift package, the Firebase iOS SDK included, to an exact version.

## Public pages

The App Store needs a Support URL and a Privacy Policy URL; Google Play needs a privacy policy URL and a page for deleting an account without the app. `tool/legal/build_site.py` builds all of them, in English and Arabic, from the app's own `assets/legal/` texts and `tool/legal/site/`:

| Page | URL |
|---|---|
| Support (both languages) | `https://mohingo.web.app/` |
| Privacy Policy | `https://mohingo.web.app/privacy` · `/ar/privacy` |
| Terms of Use | `https://mohingo.web.app/terms` · `/ar/terms` |
| Delete your account | `https://mohingo.web.app/delete-account` · `/ar/delete-account` |

1. Put the support address in `tool/legal/site.json` (`supportEmail`) and commit it. The build refuses to run without one, because every page that lists it is public.
2. Deploy (your machine): `firebase deploy --only hosting`. It rebuilds the pages first (`firebase.json` → `hosting.predeploy`). If it stops with `Error: An unexpected error has occurred` and `--debug` shows `ERR_REQUIRE_ESM`, the CLI's Node.js is too old for firebase-tools 15; `npx -y firebase-tools@14 deploy --only hosting` works on Node 20 (it did on 2026-09-24, from the owner's Mac).
3. Deploy again whenever `assets/legal/` or `tool/legal/site/` changes, so the public text is always the one the app shows.

Check the generator with `python3 -m unittest tool/legal/test_build_site.py`.
