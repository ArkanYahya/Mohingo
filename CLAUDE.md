> **What this file is:** The entry point every AI session reads first. It doesn't contain the actual decisions — it points to the docs that do, and states the few rules that are non-negotiable everywhere.
> **How to use it:** Keep this short. When a rule applies to the whole codebase and has zero exceptions, put it here. Everything else belongs in one of the linked docs below — update this list if a doc is renamed or added.

_Last verified: 2026-09-01 — product, stack, and architecture defined via brainstorming session; implementation not yet started._

# Mohingo

A CEFR-structured (A1–C2) English-learning mobile app for self-directed adult Arabic-speaking learners — offline-first, bilingual Arabic/English, covering all 4 language skills (reading, listening, writing, speaking). (See [docs/PRODUCT.md](docs/PRODUCT.md) for full detail.)

## Start here

| Doc | Purpose |
|---|---|
| [docs/PRODUCT.md](docs/PRODUCT.md) | What we're building, for whom, and what "done" means |
| [docs/ROADMAP.md](docs/ROADMAP.md) | The path from MVP (A1) through C2, and features deferred out of the MVP |
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | Domain terms — read before naming anything new |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Chosen technologies and why |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System shape, layers, folder structure |
| [docs/adr/](docs/adr/) | Record of significant decisions and why they were made |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md) | Naming, structure, commit/branch rules |
| [docs/API_CONTRACT.md](docs/API_CONTRACT.md) | Firestore collection structure and access rules (no custom REST API) |
| [docs/DATA_MODEL.md](docs/DATA_MODEL.md) | Entities, relationships, constraints |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Colors, type, spacing, component states |
| [docs/UX_PRINCIPLES.md](docs/UX_PRINCIPLES.md) | Voice, tone, error/empty states, accessibility |
| [docs/TESTING.md](docs/TESTING.md) | What must be tested and how to run it |
| [docs/SECURITY.md](docs/SECURITY.md) | Auth model, secrets handling, hard limits |

## Non-negotiable rules

- The app must work fully offline — no learning feature (lessons, exercises, speaking/writing assessment, progress tracking) may require network connectivity to function. Network is only used for content sync and account creation/sign-in. See [ADR 0001](docs/adr/0001-offline-first-firebase-only-backend.md).
- No custom backend server — Firebase (Auth, Firestore, Cloud Storage) only. See [ADR 0001](docs/adr/0001-offline-first-firebase-only-backend.md).
- Never bundle the LLM/content-generation API key (or any content-authoring credential) into the shipped app — it lives only in the separate dev-time authoring tool. See [SECURITY.md](docs/SECURITY.md).
- UI must never hardcode left/right layout or a single text direction — always use Flutter's directional (start/end) layout properties, since Arabic (RTL) and English (LTR) must both render correctly. See [DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md).
- All user-facing copy must be bilingual (Arabic + English), each language written natively for that language, never machine-translated from the other. See [UX_PRINCIPLES.md](docs/UX_PRINCIPLES.md).

## Definition of done

Docs drift the moment a change lands without its matching doc update. If a task touches the left column, updating the right-column doc — in the same session, not as a follow-up — is part of finishing the task, not optional cleanup. When you edit a doc, bump its **Last verified** line to today's date and the commit/PR if known.

| If a change touches... | Update... |
|---|---|
| A new/changed architectural decision, a hard-to-reverse choice, or a stack change | [docs/adr/](docs/adr/) (new ADR) + [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and/or [docs/TECH_STACK.md](docs/TECH_STACK.md) |
| Layers, folder structure, data flow, or a new module boundary | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| An API endpoint or payload shape | [docs/API_CONTRACT.md](docs/API_CONTRACT.md) |
| A DB table, column, or relationship | [docs/DATA_MODEL.md](docs/DATA_MODEL.md) |
| A new domain term or entity name | [docs/GLOSSARY.md](docs/GLOSSARY.md) |
| Naming, file layout, error handling, commit/branch rules | [docs/CONVENTIONS.md](docs/CONVENTIONS.md) |
| Colors, type, spacing, or a component's states | [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) |
| User-facing copy, error/empty states, accessibility | [docs/UX_PRINCIPLES.md](docs/UX_PRINCIPLES.md) |
| Test setup, commands, or coverage expectations | [docs/TESTING.md](docs/TESTING.md) |
| Auth, secrets handling, or a new hard security limit | [docs/SECURITY.md](docs/SECURITY.md) |
| Scope — a feature added, cut, or reprioritized | [docs/PRODUCT.md](docs/PRODUCT.md) |
| Level/phase sequencing (A1→C2) or a feature deferred/pulled forward | [docs/ROADMAP.md](docs/ROADMAP.md) |

If a doc's **Last verified** line is older than the code it describes, treat the doc as suspect — verify against the actual code before trusting it, and correct it while you're there.

## Commands

Project not yet scaffolded (no `pubspec.yaml`/`lib/` exist yet — docs describe the intended design, not running code). Once `flutter create` has been run per [ARCHITECTURE.md](docs/ARCHITECTURE.md)'s folder structure, these are the standard Flutter commands:

```
build: flutter build apk / flutter build ios
test:  flutter test && flutter test integration_test/
lint:  flutter analyze
run:   flutter run
```
