# ADR-003: Database Ownership

## Status

Accepted.

## Context

The current app uses **SQLite** (`config/database.yml`, adapter `sqlite3`),
not PostgreSQL. Several drafts of this migration assumed Postgres; the actual
audited adapter is SQLite, and this ADR corrects that assumption rather than
silently carrying it forward.

SQLite is file-based. This is actually convenient for this decision: "one
database per service" does not require standing up separate database
servers, connection pools, or per-service credentials in development — it
requires separate `.sqlite3` files.

## Decision

> **A service does not read or write another service's database. No
> exceptions, no "just this one read-only query".**

Concretely, once extraction happens (Phase 2+):

```text
World Service   →  storage/world_development.sqlite3   (owns planets)
Alien Service   →  storage/alien_development.sqlite3    (owns aliens, alien_powers)
Power Service   →  storage/power_development.sqlite3    (owns powers)
```

(Test/production get their own equivalents, matching current
`config/database.yml` conventions.)

SpaceRails Web keeps **no domain database of its own** — it holds only
Rails' own infrastructure needs (Solid Cache/Queue/Cable, already configured
separately in `config/cache.yml` / `config/queue.yml` / `config/cable.yml`).

No shared `ActiveRecord` model is loaded by more than one service (ADR-002 of
`Guia.md`'s general doctrine already forbids this; restated here for the
service split specifically). Each service's `Alien`/`Planet`/`Power` model
lives only inside that service's own `app/models`.

Existing primary keys (Alien/Planet/Power ids) are preserved verbatim when
data is copied into each service's own database — a cross-service reference
(e.g. an Alien's `planet_id`) must keep pointing at the same logical row.

## Consequences

- No 3 physical Postgres servers, no Docker Compose database cluster —
  three SQLite files is enough for this stage, and matches what the app
  already does.
- `belongs_to :planet` on `Alien` can no longer be a real foreign key once
  Alien and Planet are different databases; it becomes an external id with
  application-level validation via World Service's API (see ADR-004).
- Data migration (Phase 4) is a straightforward same-adapter copy: export
  each domain's rows from the current single `storage/development.sqlite3`,
  import into the new per-service file, verify row counts and ids match
  (Phase-0 baseline: 1 Planet, 11 Aliens, 2 Powers, 10 `alien_powers` rows).
