# 0012: The iOS release — Sign in with Apple, and the public pages on Firebase Hosting

**Status:** Accepted

## Context

[ADR 0010](0010-optional-accounts-and-progress-sync.md) built accounts Android-first and wrote down what iOS would owe: its own Firebase app registration and Google URL scheme, and Sign in with Apple. App Store guideline 4.8 requires an app that offers a third-party login such as Google to offer an equivalent that limits collection to name and email and lets the user hide their email, which in practice means Sign in with Apple. Apple also requires that an app deleting an account created with Sign in with Apple revoke that account's Apple tokens.

Both stores want public URLs the app did not have: the App Store needs a Privacy Policy URL and a Support URL, and Google Play needs a privacy policy URL and a page for requesting account deletion without the app. The policy and terms already exist in the app, in `assets/legal/`, in English and Arabic ([ADR 0011](0011-first-run-agreement-app-guide-and-account-deletion.md)).

## Decision

1. **Sign in with Apple, on iPhone only.** `AuthProvider.apple`, offered where `AuthRepository.supportsApple` is true, which is iOS. `FirebaseAuthRepository` signs in with Firebase's native flow (`signInWithProvider(AppleAuthProvider())`), which needs no Services ID. It requests the `email` scope only, because the app shows the account's address and never uses the learner's name. The button is drawn to Apple's rules (black on light, white on dark, the Apple logo, "Continue with Apple") and sits above Google's.
2. **Deleting an Apple account revokes its tokens.** The delete flow reauthenticates with Apple, which yields a single-use authorization code, and `deleteCurrentUser` passes it to `revokeTokenWithAuthorizationCode` before deleting the Firebase user. Revocation is **best effort**: by the time it runs, the account's cloud progress has already been deleted, so a failure (no network, or the Apple provider's key missing in Firebase) is logged and the deletion continues. The confirm button for an Apple account reads "Delete account", because a red button may not be dressed as Sign in with Apple.
3. **The public pages are generated from the app's own copies and served by Firebase Hosting** on the existing project. `tool/legal/build_site.py` renders `assets/legal/` (privacy, terms) and `tool/legal/site/` (support, delete account) into `build/legal_site/`, in English and Arabic. `firebase.json` runs it before every hosting deploy, so the public policy is always the text the learner accepted in the app. Hosting stays within [ADR 0001](0001-offline-first-firebase-only-backend.md)'s "Firebase only".
4. **One app id on both platforms: `com.northstorm.mohingo`.** Apple would not register the original `com.mohingo.mohingo`, so the iOS bundle id became `com.northstorm.mohingo`, and the Android `applicationId` and `namespace` followed before either store had published the app, since both are permanent after that. Each platform has a Firebase app under the new id; the `com.mohingo.mohingo` registrations are unused.
5. **iOS declares Arabic.** `CFBundleLocalizations` lists `en` and `ar`, and `ar.lproj/InfoPlist.strings` holds the Arabic microphone and speech-recognition prompts, so iOS shows its own prompts in the learner's language and the App Store lists both languages.

## Alternatives considered

- **Hide Google sign-in on iOS** (email only, so guideline 4.8 does not apply). Less work, but a learner who made a Google account on Android could not sign in on an iPhone, which breaks the cross-device sync that accounts exist for.
- **The `sign_in_with_apple` package.** It adds a dependency for what `firebase_auth` already does natively on iOS.
- **Apple on Android too**, through Apple's web flow. It needs a Services ID, a return URL and a Chrome Custom Tab flow that cannot be tested in this environment, and the store rule behind this decision is the App Store's. An account made with Apple therefore cannot sign in on Android yet (see Consequences).
- **Making revocation block deletion.** Deleting the cloud progress first and then refusing to delete the account over a revocation error would leave an empty account the learner asked to be rid of.
- **Hand-written HTML pages, or GitHub Pages.** A second copy of the policy would drift from the one in the app, and a second host adds an account and a domain for nothing.

## Consequences

- An account created with Sign in with Apple can sign in only on an iPhone. Enabling it on Android is one line in `supportsApple`, once the Apple provider's Services ID has Firebase's return URL (`https://mohingo.firebaseapp.com/__/auth/handler`) and the flow has been tried on a device.
- Revocation works only once the Apple provider in Firebase has the Services ID, Team ID, Key ID and private key ([FIREBASE_SETUP.md](../FIREBASE_SETUP.md)). Without them, deletion still works but the app stays listed under the learner's Apple ID until they remove it.
- The Google URL scheme in `Info.plist` depends on `GoogleService-Info.plist`, which only exists once the iOS app is registered, so it is a documented step rather than a committed file.
- Hosting deploys fail until `tool/legal/site.json` has a support email, on purpose: the store listings and the delete-account page publish it.
- Nothing in this ADR has run on an iPhone yet. An unsigned release build compiles with Xcode 26.6 (2026-09-24). The App Store has required Xcode 26 since 28 April 2026. The development Mac is an Intel MacBook Pro (2020) on macOS Tahoe 26.7: Xcode 27 does not run on it, but Xcode 26's Universal build does, and it can make uploads until Apple raises the minimum to the iOS 27 SDK. After that, iOS builds need an Apple silicon Mac, for example a cloud one ([README.md](../../README.md), Releasing (iOS)).
