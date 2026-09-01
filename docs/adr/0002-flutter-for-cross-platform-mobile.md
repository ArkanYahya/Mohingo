# 0002: Flutter for cross-platform mobile (iOS + Android)

**Status:** Accepted

## Context

Mohingo must ship on both iOS and Android, built solo. Maintaining two native codebases (Swift + Kotlin) isn't feasible for one person, so a cross-platform framework is required. The app also has a hard requirement most cross-platform apps don't: a bilingual Arabic (RTL) / English (LTR) UI with full layout mirroring, not just translated strings.

## Decision

Build the app in Flutter (Dart). Flutter has mature, first-class RTL support (directional layout properties, automatic mirroring) and produces a single codebase for both platforms.

## Alternatives considered

- **React Native (Expo)** — strong ecosystem and would allow sharing TypeScript logic/types with a backend. Rejected because (a) [0001](0001-offline-first-firebase-only-backend.md) means there is no custom backend to share types with, removing that advantage, and (b) Flutter's RTL support was judged more mature/reliable for a genuinely bilingual, dual-direction UI, which is a core product requirement, not a nice-to-have.
- **Native Swift + Kotlin, two codebases** — rejected outright as infeasible for solo, ongoing maintenance.

## Consequences

- Single codebase for iOS + Android, sustainable solo.
- RTL/LTR correctness is a first-class framework feature rather than something bolted on, reducing the risk of layout bugs for Arabic users.
- Locks the team into Dart and Flutter's plugin ecosystem for any native-capability access (e.g. on-device speech-to-text, see [0003](0003-on-device-speech-writing-assessment-for-mvp.md)) — acceptable, as the ecosystem covers the app's current needs (`speech_to_text`, Firebase Flutter SDKs, Drift).
