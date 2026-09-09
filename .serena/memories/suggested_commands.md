# Suggested Commands

```
flutter test                                                # unit + widget suite
dart format --set-exit-if-changed .                          # whole-repo format check
flutter analyze                                              # static analysis — must be clean
dart run build_runner build --delete-conflicting-outputs      # after Drift table / @riverpod provider edits
flutter pub get
```

A one-off Dart script with no test harness runs directly: `dart run path/to/script.dart` — used for e.g. WCAG-contrast/colour-sweep calculations outside the app itself.

Windows dev machine — shell notes:
- Both a Bash tool (Git Bash, POSIX-ish) and a PowerShell tool are available; prefer POSIX/forward-slash paths in Bash calls. PowerShell 5.1 has no `&&`/`||` chaining.
- `flutter analyze` (~2 min) and the full `flutter test` suite (~1–1.5 min, 370+ tests as of writing) are slow — run them in the background and keep working rather than blocking on them.

No CI configured yet (TBD Codemagic vs GitHub Actions, see docs/TECH_STACK.md) — format/analyze/test are enforced only by convention, not a gate.
