# World Service

## Purpose

Owns the World/Planet domain in SpaceRails' service-oriented architecture.
See [`../../docs/architecture/`](../../docs/architecture/) for the full
migration plan and ADRs — this README only covers what's local to this
service.

## Current status: **verified data migration (Phase 4)**

This is an independently bootable Rails API service with its own database,
its own Planet model/schema, a versioned `/api/v1/planets` API (see
[`contracts/worlds/v1/`](../../contracts/worlds/v1/README.md)), and — as of
Phase 4 — a verified copy of root's Planet data, with ids and timestamps
preserved exactly.

**Root SpaceRails is still the runtime source of truth.** Phase 4 proved
data can cross the service boundary without losing identity; it did not
switch any consumer over. No root code reads from World Service yet — see
`docs/architecture/MIGRATION_PLAN.md`'s Phase 4/5 records for what that
means concretely.

What this service currently owns:

- its own runtime (Rails 8.1.3.1, API mode)
- its own configuration
- its own SQLite database, containing a verified migrated copy of Planet
  data (`lib/planet_importer.rb`, `bin/rails planets:import`)
- `/up` health check
- `/api/v1` service identity endpoint
- `/api/v1/planets` CRUD API (index/show/create/update/destroy)
- its own test suite, RuboCop config, Brakeman/bundler-audit tooling

What it does **not** own yet: runtime authority (root's `Planet` table is
still what the web app actually reads/writes — see Phase 5), planetary
generation/environment logic (out of scope for the whole migration until
the product explicitly asks for it — see `Guia.md`).

## Migrating Planet data from root

```
# in the root app
bin/rails planets:export

# in services/worlds
bin/rails planets:import
```

Reads/writes a neutral JSON artifact at `tmp/migration/planets_export.json`
(repo-root-relative, gitignored). Preserves ids and timestamps; safe to
re-run (identical rows are skipped, conflicting ones raise and roll back
the whole import — see `lib/planet_importer.rb` and its tests). This is
one-time migration tooling, not part of the service's runtime request
path.

If this service's Planet data ever drifts from root's (for example, after
manual QA that intentionally modified a record — see the Phase 5/6
migration records), restore an exact snapshot with:

```
bin/rails planets:restore_from_canonical
```

**Destructive to this service's own database only.** It wipes World
Service's `Planet` table and reimports the canonical export — safe only
while World Service is non-authoritative (today). It never touches root's
database. `planets:import`'s normal conflict detection is untouched by
this — the restore task just guarantees an empty destination first.

## Boot

```
cd services/worlds
bundle install
bin/rails db:prepare
bin/rails server -p 3001
```

Runs independently of the root SpaceRails app (default port `3000`) — both
can run at the same time, on separate SQLite databases
(`services/worlds/storage/*.sqlite3` vs the root app's `storage/*.sqlite3`).

## Test

```
bin/rails test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

All run scoped to this service only.
