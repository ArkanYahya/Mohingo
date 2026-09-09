# Task Completion Checklist

Before considering a coding task done:

1. `flutter test` — full suite must pass.
2. `dart format --set-exit-if-changed .` — must report no changes.
3. `flutter analyze` — must report "No issues found!".
4. If the change touches anything in CLAUDE.md's Definition-of-Done table (architecture, folder structure, API/data model, naming, design tokens, copy/UX, test coverage, security, scope, roadmap) — update the matching doc under `docs/` in the *same* change, and bump its "Last verified" line. See `mem:conventions` for the doc-mapping shortcut.
5. Only commit when the user explicitly asks — treat committing as an explicit-request action, never an automatic step at the end of a task.
