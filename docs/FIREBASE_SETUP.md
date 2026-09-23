> **What this file is:** How this repository is connected to its Firebase project, and how to redo it — for a new machine, a new developer, or a new platform. The design is [ADR 0010](adr/0010-optional-accounts-and-progress-sync.md); the data contract is [API_CONTRACT.md](API_CONTRACT.md).
> **How to use it:** Follow the steps in order. Anything that needs the project owner's Google account is marked **(console)** or **(your machine)**; everything else is already in the repository.

_Last verified: 2026-09-23 (`claude/firebase-auth-sync-ji1cww`) — the project is connected: **`mohingo`**, Android app `1:219416710516:android:484ea34d5b308574bd3021`, Email/Password and Google enabled, Firestore `(default)` in **`me-central2` (Dammam)**, rules and indexes deployed, the owner's debug SHA-1/SHA-256 registered. Steps 1-6 below are done; step 7 and iOS are not._

# Firebase setup

## What's already in the repository

- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` (`pubspec.yaml`).
- `lib/main.dart` starts Firebase from `lib/firebase_options.dart`. Until `flutterfire configure` has run, that file is a **placeholder** that throws; the app catches it and runs local-only (no sign-in offered). Every learning feature works either way.
- `firestore.rules`, `firestore.indexes.json` (empty — no composite index is needed), `firebase.json` (rules, indexes, emulator ports).
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
     --android-package-name=com.mohingo.mohingo
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
7. **Restrict the API key** (console, recommended): Google Cloud console → APIs & Services → Credentials → the Android key → restrict to Android apps with package `com.mohingo.mohingo` and your SHA-1s.

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

## iOS (not done yet)

1. `flutterfire configure --platforms=android,ios --ios-bundle-id=com.mohingo.mohingo` (writes `ios/Runner/GoogleService-Info.plist`).
2. Add the `REVERSED_CLIENT_ID` from that plist as a URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`), for Google sign-in.
3. Offer **Sign in with Apple** — App Store guideline 4.8 requires it once Google sign-in is offered. `AuthProvider` has room for it; see [ROADMAP.md](ROADMAP.md).
4. `cd ios && pod install`, then build on a Mac.
