# Alien Service

## Purpose

Owns the Alien **persistent domain** in SpaceRails' service-oriented
architecture: Alien identity/fields, and the `alien_powers` relationship
(ADR-002 — this is the only service allowed to write that relationship).
See [`../../docs/architecture/`](../../docs/architecture/) for the full
migration plan and ADRs — this README only covers what's local to this
service.

**What this service does NOT own:** the Xenobiology Laboratory
experience — the containment chamber, scanner, dossier, archive,
workstation, camera, Three.js, and the persistent Universe Engine all
remain root/Web's responsibility. This service has no views, no
JavaScript, no CSS — it is a data API. It also has no local `Planet` or
`Power` model/table: those are external identifiers validated over HTTP
against World Service and Power Service respectively, never a database
foreign key.

## Current status: **verified data migration (Phase 9)**

This is an independently bootable Rails API service with its own
database, its own Alien + `alien_powers` model/schema, a versioned
`/api/v1/aliens` API (see
[`contracts/aliens/v1/`](../../contracts/aliens/v1/README.md)), and a
verified copy of root's Alien and `alien_powers` data, with ids,
relationships, and timestamps preserved exactly.

**Root SpaceRails is still the runtime source of truth.** Phase 9 proved
data (and, uniquely among the three services, a *relationship*) can cross
the service boundary without losing identity or losing the FK/validation
guarantees root relies on — see the Phase 9 migration record for the
concrete evidence (a real database check proving `planet_id`/`power_id`
are no longer enforced by a local foreign key here, on purpose).

What this service currently owns:

- its own runtime (Rails 8.1.3.1, API mode)
- its own configuration, including its own outbound clients to World
  Service and Power Service (`app/clients/worlds_client.rb`,
  `app/clients/powers_client.rb` — separate, small implementations, not
  shared with root's own clients of the same name)
- its own SQLite database: `aliens` (with a plain, non-FK `planet_id`
  column) and `alien_powers` (with a real local FK to `aliens.id`, and a
  plain, non-FK `power_id` column)
- `/up` health check
- `/api/v1` service identity endpoint
- `/api/v1/aliens` CRUD API (index/show/create/update/destroy) —
  `create`/`update` validate `planet_id` against World Service and every
  `power_id` against Power Service (one batched call, not one per id)
  before persisting; see `contracts/aliens/v1/README.md` for the full
  error contract (`WORLD_NOT_FOUND`, `POWER_NOT_FOUND`,
  `DEPENDENCY_UNAVAILABLE`)
- its own test suite, RuboCop config, Brakeman/bundler-audit tooling

**Delete semantics differ from World/Power's known gaps, on purpose:**
because `alien_powers` now lives in this same database as `aliens`,
`DELETE /api/v1/aliens/:id` removes its own `alien_powers` rows locally
via `dependent: :destroy` — this is **no longer a distributed operation**,
unlike Planet→Alien or Power→alien_powers deletion (both still deferred
per ADR-002, now technically possible to orchestrate since Alien Service
exists, but not implemented in Phase 9 — see the migration record).

## Migrating Alien + alien_powers data from root

```
# in the root app
bin/rails aliens:export

# in services/aliens
bin/rails aliens:import
```

Reads/writes a neutral JSON artifact at `tmp/migration/aliens_export.json`
(repo-root-relative, gitignored). Preserves Alien ids/fields/timestamps
and the exact `alien_id`/`power_id` relationship set; safe to re-run
(identical rows are skipped, conflicting ones raise and roll back the
*entire* batch — aliens and alien_powers together — see
`lib/alien_importer.rb` and its tests). Does not embed Planet or Power
definitions, only their ids. This is one-time migration tooling, not part
of the service's runtime request path.

## Boot

```
cd services/aliens
bundle install
bin/rails db:prepare
bin/rails server -p 3003
```

Runs independently of the root SpaceRails app (`:3000`), World Service
(`:3001`), and Power Service (`:3002`) — all four can run at the same
time, on separate SQLite databases. Note: unlike World/Power, this
service's own `create`/`update` actions need World Service and Power
Service reachable to validate references — its *test suite* does not
(those calls are stubbed), but exercising the API for real does.

## Test

```
bin/rails test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

All run scoped to this service only — no live World/Power/root process
required (dependency validation is stubbed in tests, see
`test/test_helper.rb`).
