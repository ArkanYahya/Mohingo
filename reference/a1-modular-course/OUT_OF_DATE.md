# This package is behind the app

The app loads `assets/content/en/A1/a1-course-bundle.json`, and since 2026-09-08 every content fix has gone into that file directly:

- structured `EvaluationSpec`s replaced the old rubric names;
- the Final Mission and Final Assessment were fixed;
- on 2026-09-19, English prompts, choice options and grammar meanings were cleaned up.

This package's sources and `dist/a1-course-bundle.json` do not have those fixes.

**Do not run `tools/build-a1.mjs` and copy its output into the app.** That would undo all of the fixes above. To author here again, first port the shipped bundle's changes back into these sources.

See `docs/ARCHITECTURE.md` in the app repo, section "Content".
