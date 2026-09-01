> **What this file is:** The auth model, how secrets are handled, and the hard limits nothing should cross (e.g. "never log PII"). Security rules are exactly the kind of thing that must never be re-derived per session — they must be inherited.
> **How to use it:** Treat every rule here as a hard constraint, not a guideline. If a task seems to require violating one, stop and raise it rather than making a local exception.

_Last verified: 2026-08-18 — initial scaffold, no real content yet._

# Security

## Auth model

- Mechanism (session/JWT/OAuth...): TBD
- Roles/permissions: TBD
- Token lifetime/refresh: TBD

## Secrets handling

- Where secrets live (env vars, vault, etc.): TBD
- Rule: never commit secrets, never ship secrets to the client: (standing rule)

## Data handling

- PII fields: TBD
- What must never be logged: TBD
- Encryption at rest / in transit: TBD

## Hard limits

- TBD — e.g. "no client-side secret keys", "no raw SQL string concatenation", "all external input validated at the boundary"

## Dependency / vulnerability policy

TBD — how third-party packages are vetted, update cadence.
