> **What this file is:** What must be tested, at what level, and how to run it. Keeps test coverage expectations consistent instead of depending on whichever session happens to be writing a feature.
> **How to use it:** Check before adding a feature — what test(s) does this convention require? Update the commands section the moment the test setup changes so it never goes stale.

_Last verified: 2026-09-01 — initial testing conventions established via brainstorming session._

# Testing

## Levels & expectations

| Level | Tool | Required for | Coverage bar |
|---|---|---|---|
| Unit | `flutter_test` / `package:test` | Repository logic, progress-gating rules, Riverpod providers/notifiers | All non-trivial logic (gating, sync conflict handling, placement-test scoring) |
| Widget | `flutter_test` (`WidgetTester`) | Individual screens/components, especially bilingual (Arabic/English) and RTL/LTR rendering | Key screens: exercise types, unit/level overview, placement test |
| Integration/E2E | `integration_test` package | Critical end-to-end flows on a real device/simulator | The flows listed below |

## What must be tested

- All progress-gating logic (unit pass → unlock next unit → block/level completion) — this is the core mechanic the whole app depends on
- Offline behavior: exercises completable and progress recorded with no network connection
- Sync behavior: local progress correctly pushes to Firestore when connectivity returns, and doesn't duplicate/lose Attempts
- Critical end-to-end flows: onboarding → placement test → first unit → unit assessment pass/fail → progress reflected
- RTL/LTR rendering correctness for any screen carrying bilingual content

## What doesn't need tests

- Generated code (Drift schema/DAOs, Firestore model boilerplate)
- Trivial getters/simple data classes with no logic
- Third-party package wrappers with no added logic (e.g. a thin call to `speech_to_text`)

## Running tests

```
flutter test                      # unit + widget tests
flutter test integration_test/    # integration/E2E tests (requires device/simulator)
```

## CI

None configured yet — to be set up once the CI/CD tool is chosen (see [TECH_STACK.md](TECH_STACK.md), currently TBD between Codemagic and GitHub Actions).
