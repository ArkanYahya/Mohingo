> **What this file is:** The high-level shape of the system — layers, boundaries, data flow, folder structure. The single biggest lever for keeping AI sessions from drifting, since most inconsistency comes from this not being written down.
> **How to use it:** Read before adding a new module or changing how data flows. If a change alters this shape, update the diagram/description *and* record the reasoning as an [ADR](adr/).

_Last verified: 2026-08-18 — initial scaffold, no real content yet._

# Architecture

## Overview

TBD — one paragraph on the overall shape (e.g. "client-server, layered backend, relational DB").

## Layers / boundaries

```
TBD — e.g.
client (UI) -> API layer -> service layer -> repository layer -> database
```

Rules for crossing layers (e.g. "UI never talks to the DB directly"): TBD

## Folder structure

```
TBD
```

## Key flows

TBD — how a request/data typically moves through the system (e.g. request → validation → service → persistence → response).

## Cross-cutting concerns

- **Auth:** TBD (detail in [SECURITY.md](SECURITY.md))
- **Error handling:** TBD
- **Logging / observability:** TBD
- **Config / secrets:** TBD

## Deployment topology

TBD
