> **What this file is:** The source of truth for what the API looks like from the outside — endpoints, request/response shapes, status codes. Prevents the frontend and backend (or different sessions working on either) from silently diverging.
> **How to use it:** Update *before or alongside* changing an endpoint, not after. If the project adopts a formal schema (OpenAPI/GraphQL SDL), that generated/authored file becomes the real source of truth — keep this doc as a human-readable index pointing to it.

_Last verified: 2026-08-18 — initial scaffold, no real content yet._

# API Contract

## Schema source of truth

TBD — e.g. `openapi.yaml` at repo root / GraphQL schema file path. If none yet, this doc is authoritative until one exists.

## Conventions

- Base URL / versioning: TBD
- Auth header format: TBD
- Standard error response shape: TBD
- Pagination pattern: TBD

## Endpoints

| Method | Path | Purpose | Auth required |
|---|---|---|---|
| TBD | TBD | TBD | TBD |
