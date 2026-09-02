# Mohingo

Offline-first, bilingual (Arabic/English) CEFR English-learning app for self-directed adult Arabic-speaking learners.

Full documentation — product scope, architecture, data model, and every other project decision — lives in [`docs/`](docs/), starting from [CLAUDE.md](CLAUDE.md). This file is a minimal build pointer; a fuller setup/build/troubleshooting README is a Phase 10 deliverable per CLAUDE.md's implementation workflow.

## Commands

```
flutter pub get                          # install dependencies
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift/Riverpod code after editing tables/providers
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

## Status

Scaffolding in progress — see [CLAUDE.md](CLAUDE.md) for what's built and what's next.
