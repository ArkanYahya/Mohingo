> **What this file is:** The entities, their relationships, and the constraints that matter (uniqueness, ownership, required fields). Keeps the schema's intent legible even as migrations accumulate.
> **How to use it:** Update when an entity or relationship changes. If migration files exist, treat them as the literal source of truth and keep this as the readable summary + rationale.

_Last verified: 2026-08-18 — initial scaffold, no real content yet._

# Data Model

## Entities

### TBD (entity name)

| Field | Type | Constraints | Notes |
|---|---|---|---|
| TBD | TBD | TBD | TBD |

## Relationships

TBD — e.g. "One User has many Orders. One Order has many OrderItems, each referencing one Product."

## Key constraints & invariants

TBD — rules that must always hold (e.g. "an Order's total always equals the sum of its items").

## Migration source

TBD — path to migration files, if any.
