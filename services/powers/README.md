# Power Service

## Purpose

Owns the Power **definition/catalog** in SpaceRails' service-oriented
architecture. See [`../../docs/architecture/`](../../docs/architecture/)
for the full migration plan and ADRs — this README only covers what's
local to this service.

**What this service does NOT own:** `alien_powers` — the fact that a
specific Alien possesses a specific Power. That relationship belongs to
Alien Service (ADR-002), even though today it still physically lives in
root's database. This service has no `Alien` model, no `alien_powers`
table, and never queries Alien Service's or root's database.

## Current status: **verified data migration (Phase 7)**

This is an independently bootable Rails API service with its own database,
its own Power model/schema, a versioned `/api/v1/powers` API (see
[`contracts/powers/v1/`](../../contracts/powers/v1/README.md)), and a
verified copy of root's Power data, with ids and timestamps preserved
exactly.

**Root SpaceRails is still the runtime source of truth.** Phase 7 proved
data can cross the service boundary without losing identity, following
the same pattern already proven for World Service (Phase 4); it did not
switch any consumer over — no root code reads from Power Service.

What this service currently owns:

- its own runtime (Rails 8.1.3.1, API mode)
- its own configuration
- its own SQLite database, containing a verified migrated copy of Power
  data (`lib/power_importer.rb`, `bin/rails powers:import`)
- `/up` health check
- `/api/v1` service identity endpoint
- `/api/v1/powers` CRUD API (index/show/create/update/destroy)
- its own test suite, RuboCop config, Brakeman/bundler-audit tooling

**Known semantic gap:** root's `Power#destroy` cascades to `alien_powers`
today (`dependent: :destroy`, proven in
`test/models/power_alien_powers_coupling_test.rb` at the root app). This
service's `DELETE /api/v1/powers/:id` cannot reach `alien_powers` — it
never will, by design (ADR-002/ADR-003: no cross-service database access).
Full delete-semantic parity was deferred until Alien Service exists and a
cross-service cleanup workflow is designed, the same class of deferral
ADR-002 already commits to for Planet → Alien. **As of Phase 9, Alien
Service exists and owns `alien_powers` locally** — the orchestration is
now technically implementable (Power Service could call Alien Service's
API to clean up on delete) but has not been built; this remains
documented debt, not a silent gap. See
[`contracts/powers/v1/README.md`](../../contracts/powers/v1/README.md)
for the full explanation.

## Migrating Power data from root

```
# in the root app
bin/rails powers:export

# in services/powers
bin/rails powers:import
```

Reads/writes a neutral JSON artifact at `tmp/migration/powers_export.json`
(repo-root-relative, gitignored). Preserves ids and timestamps; safe to
re-run (identical rows are skipped, conflicting ones raise and roll back
the whole import — see `lib/power_importer.rb` and its tests). Does **not**
export/import `alien_powers` — see "Purpose" above. This is one-time
migration tooling, not part of the service's runtime request path.

## Boot

```
cd services/powers
bundle install
bin/rails db:prepare
bin/rails server -p 3002
```

Runs independently of the root SpaceRails app (`:3000`) and World Service
(`:3001`) — all three can run at the same time, on separate SQLite
databases.

## Test

```
bin/rails test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

All run scoped to this service only.
