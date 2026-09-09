# Mohingo — Core

Offline-first, bilingual (Arabic/English) CEFR English-learning Flutter app (iOS+Android). No backend in v1 — fully local (Drift/SQLite), no Firebase, no accounts. See ADR 0004.

`docs/` is the source of truth, not this memory graph. Root entry point: `CLAUDE.md`. Every doc under `docs/` carries its own "Last verified" line — treat a doc as suspect if it looks older than the code it describes, and verify against the code before trusting it.

- docs/ARCHITECTURE.md — layers, folder structure, key flows
- docs/CONVENTIONS.md — naming, file layout, error handling, git
- docs/TESTING.md — coverage requirements, platform-service fakes, test commands
- docs/DESIGN_SYSTEM.md — colour tokens (ColorScheme roles), type, spacing
- docs/DATA_MODEL.md, docs/GLOSSARY.md, docs/adr/ — entities/relationships, domain terms, decisions

Non-negotiable rules (also in CLAUDE.md — repeated here since they're easy to violate by habit, not because CLAUDE.md is unreliable):
- App must work fully offline — no learning feature may require network connectivity.
- No custom backend server — Firebase only, and even that isn't wired up in v1.
- Never bundle LLM/content-authoring API keys into the shipped app.
- UI must use directional (start/end) layout properties, never hardcoded left/right — Arabic is RTL.
- All user-facing copy is bilingual (Arabic + English), natively written per language, never machine-translated.

Further memories: `mem:tech_stack`, `mem:suggested_commands`, `mem:conventions`, `mem:task_completion`.
