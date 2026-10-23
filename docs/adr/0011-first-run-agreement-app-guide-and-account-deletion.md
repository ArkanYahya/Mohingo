# 0011: First-run agreement, app guide and account deletion (1.0.0)

**Status:** Accepted (2026-09-23, `release/v1.0.0`)

## Context

Preparing 1.0.0, the first public release, the product owner asked for three things that shape how the app starts and what a learner can do with their account:

1. A first-run **privacy / licence agreement**, worded from what the app actually does, remembered with a version so that a material change can ask again.
2. A first-run **guide** that teaches the real interface (not marketing slides), can be skipped, and can be reopened later.
3. **Account controls** a store expects. Google Play requires an app that lets people create an account to let them delete it in the app ([ADR 0010](0010-optional-accounts-and-progress-sync.md) listed this as not done).

What leaves the phone, verified in the code before any wording was written:

| What | Who receives it | When |
|---|---|---|
| Email + password, or the Google account's basic profile | Firebase Authentication (Google) | Only if the learner signs in |
| Name, progress, answers (typed text / recognised text), test results, review schedules, enrolments | Cloud Firestore (Google), `me-central2` | Only while signed in (ADR 0010) |
| The text of some typed answers (writing tasks whose rubric has `onlineRefinement`) | LanguageTool (`api.languagetool.org`, LanguageTooler GmbH) | When online, guest or not (ADR 0005). No name, account or identifier is sent |
| Audio of a spoken answer | The phone's system speech recogniser (Google on most Android phones, Apple on iOS), which may process it online | Only while the learner speaks an answer; Mohingo keeps the text, never audio |

There are no analytics, crash-reporting, advertising or tracking SDKs. Lesson audio is bundled (ADR 0008).

Because data can leave the phone even without an account (the grammar check, speech recognition), a "no data collected, no agreement needed" notice would have been untrue.

## Decision

1. **A first-run agreement screen (`/welcome`), gated by the router.** After the curriculum loads, every route redirects to `/welcome` until the current agreement is accepted. It states what Mohingo is, then four plain points (progress stays on the phone; the account is optional and goes to Google Firebase; some typed answers go to LanguageTool; speech recognition may process audio online), links to the full Privacy Policy and Terms of Use (readable before accepting), a language switch, and **Accept and continue**. There is no decline button: the learner can leave the app, as with any store app.
2. **Versioned acceptance, independent of the app version.** `kAgreementVersion` (`lib/features/legal/domain/legal_documents.dart`) is stored as `legal.acceptedAgreementVersion` (with `legal.acceptedAgreementAt`) in SharedPreferences — device-level, not per learner or account, and untouched by Reset progress. Raising the constant shows the screen again with a "we've updated" notice. Most releases change neither document, so tying it to the app version would re-ask for nothing.
3. **The documents are data, not code.** `assets/legal/{privacy,terms}_{en,ar}.md`, rendered by a small Markdown subset renderer (`SimpleMarkdown`), so they can be reviewed by a lawyer and replaced without touching logic. Each language is written natively. They make no regulatory claims and name no contact beyond the store listing's developer contact.
4. **The app guide is a coach-mark tour over the real Home screen and tab bar.** `AppGuideOverlay`, hosted by `AppShellScaffold`, dims the shell and cuts out the control each step explains, found through `GlobalKey`s (`AppGuideTargets`), scrolled into view and measured after layout — correct at any size, text scale and direction. Eight steps: intro, level and streak, the continue card, the journey (how a level is organised), Learn (with the four progress marks), Review, Tests, Settings (mentioning accounts only in builds that have them). Back / Next / Skip / Done; system back closes it; a step whose control is not on screen centres its card instead of pointing at nothing. No new dependency.
5. **Start-up order:** splash (content loads) → agreement (first launch, or a new agreement version) → Home, where the guide starts once → the app. Sign-in is never a gate; it stays optional in Settings, so the guide is never behind an account screen and guests are never blocked. The guide's completion is `appGuide.completedVersion` (`kAppGuideVersion`); Settings → Help & information → **App guide** starts the same tour again (switching to Home first).
6. **Delete account, in the app.** Settings → Account & sync → Delete account: a confirmation that says exactly what goes (the account, its cloud copy, this account's progress on this phone) and what stays (guest progress), then a fresh sign-in (password, or picking the Google account again — Firebase deletes only a recently authenticated account), then: pause sync and wait for any run in flight, delete every Firestore record under `users/{uid}` and the account document, delete the Firebase Auth user, return the device to its guest learner, and delete the account's local learner row (`AppDatabase.deleteLearner`). The existing Security Rules already let an owner delete their documents; no rules change.
7. **The colour-theme picker is retired.** One brand accent (`kAppColorSeed`, Calm Teal); Settings offers Light / Dark / Automatic. The stored `settings.colorSeed` is removed at start-up (`removeRetiredPreferences`). `AppColorSeed` stays as tested theme infrastructure.

## Consequences

- A fresh install shows two screens before Home (agreement, then the guide over Home); a returning learner sees neither. An install upgraded from 0.1 sees the agreement once (it has never accepted one) and the guide once. No progress, preference or database row is touched by either.
- Any change to what leaves the device — a new SDK, a new endpoint, a new synced field — must update `assets/legal/privacy_*.md` and, if material, raise `kAgreementVersion`.
- Deleting an account needs a connection; offline, the dialog says so and nothing is deleted. If the cloud copy is deleted but the account deletion itself then fails, the learner can simply try again.
- The privacy policy still has to be hosted at a public URL for the store listings; the in-app text is the source.
