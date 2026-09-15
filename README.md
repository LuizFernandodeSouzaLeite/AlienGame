# SpaceRails

SpaceRails is an interactive interstellar scientific database — a
diegetic space-station experience, not a themed CRUD app. See `Guia.md` for
the full product/architecture doctrine before making product or UI changes.

## Setup

```
bin/setup
bin/dev
```

Ruby `4.0.6` (see `.ruby-version`), Rails `8.1.3.1`, SQLite (development/test),
Propshaft + Importmap (no Node build step required).

## Testing

```
bin/rails test
bundle exec rubocop
bundle exec brakeman -q
```

### CI

This repository is a monorepo of independently deployable Rails
applications (ADR-005), and CI (`.github/workflows/ci.yml`) validates
each one independently — a green run means root **and** World Service
**and** Power Service all pass, not just root:

```
Root / (scan_ruby, scan_js, lint, test, system-test)   — existing jobs
Worlds / Quality   — tests, RuboCop, Brakeman, bundler-audit
Powers / Quality   — tests, RuboCop, Brakeman, bundler-audit
Aliens / Quality   — tests, RuboCop, Brakeman, bundler-audit
```

Each service job runs entirely from its own directory against its own
`Gemfile.lock` — no dependency on root, on another service, or on any
live server. To reproduce a service's CI job locally:

```
cd services/worlds   # or services/powers, or services/aliens
bin/rails db:test:prepare test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## Architecture

SpaceRails today is a single Rails application. It is in the middle of a
**deliberately incremental, documented** migration toward a service-oriented
architecture — see [`docs/architecture/`](docs/architecture/):

- `ADR-001` through `ADR-005` — why SOA, the domain boundaries (World /
  Alien / Power / Web), database ownership, HTTP-first communication, and
  why this stays a monorepo.
- `MIGRATION_PLAN.md` — the live phase-by-phase tracking document,
  including the audited dependency map and phase status.

As of this writing: **Phase 9 (Alien Service extraction)**.
[`services/worlds/`](services/worlds/), [`services/powers/`](services/powers/),
and [`services/aliens/`](services/aliens/) are all independently bootable
Rails API services, each with its own database, its own domain API, and a
verified migrated copy of its data. Root's own `Planet`/`Power`/`Alien`
tables are still the **runtime source of truth** — nothing here reads or
writes through any service by default. Runtime cutover was deliberately
deferred through Phase 6-8 because root's `Alien` had a real, enforced
database foreign key to its local `Planet` (and `alien_powers` to
`Power`); Phase 9 removed that structural blocker (Alien Service's own
`planet_id`/`power_id` are plain external identifiers, validated over
HTTP, never a local foreign key) — see
`docs/architecture/MIGRATION_PLAN.md`'s Phase 6 and Phase 9 records for
the evidence.

```
# terminal 1
bin/dev                                    # root app,        :3000

# terminal 2
cd services/worlds && bin/rails server -p 3001   # World Service, :3001

# terminal 3
cd services/powers && bin/rails server -p 3002   # Power Service, :3002

# terminal 4
cd services/aliens && bin/rails server -p 3003   # Alien Service, :3003
```

### Shadow reads (Phase 5)

Root can optionally query World Service on every Planet read, purely to
compare the two copies — it never changes what a page renders. Off by
default:

```
WORLD_SHADOW_READS_ENABLED=true bin/rails server   # root app, with shadow reads on
```

Configuration (all optional, sensible development defaults):

```
WORLD_SERVICE_URL              default: http://127.0.0.1:3001
WORLD_SERVICE_OPEN_TIMEOUT     default: 1 (seconds)
WORLD_SERVICE_READ_TIMEOUT     default: 2 (seconds)
WORLD_SHADOW_READS_ENABLED     default: false
```

With shadow reads on, visiting `/`, `/aliens`, or `/planets` logs one line
per distinct Planet involved (never one per Alien — see
`app/services/worlds/planet_directory.rb`'s dedup):

```
service=worlds operation=shadow_planet_read planet_id=1 result=match
```

`result` is one of `match`, `mismatch` (with `fields=...`), `remote_not_found`,
`remote_unavailable`, or `invalid_contract`. If World Service is down or
World Service is not running, pages still render normally — the read simply
logs `remote_unavailable` (see `app/clients/worlds_client.rb` and
`docs/architecture/MIGRATION_PLAN.md`'s Phase 5 record for the full failure
semantics).

### Power shadow reads (Phase 8)

Same idea, for Power *definitions* only — never for `alien_powers` (which
Power Service has no concept of; see ADR-002). Off by default:

```
POWER_SHADOW_READS_ENABLED=true bin/rails server   # root app, with shadow reads on
```

```
POWER_SERVICE_URL              default: http://127.0.0.1:3002
POWER_SERVICE_OPEN_TIMEOUT     default: 1 (seconds)
POWER_SERVICE_READ_TIMEOUT     default: 2 (seconds)
POWER_SHADOW_READS_ENABLED     default: false
```

`app/services/powers/power_directory.rb` deduplicates by Power id and
uses a single `GET /api/v1/powers` list call for a whole page — 11 Aliens
sharing 2 Powers logs exactly 2 `shadow_power_read` lines (one per unique
Power), never one per Alien or per `alien_powers` row. Both
`WORLD_SHADOW_READS_ENABLED` and `POWER_SHADOW_READS_ENABLED` can be set
together; each fails independently (one service being down never affects
the other's shadow result or the page).

### Alien shadow reads (Phase 9)

Compares durable Alien fields (`name`, `age`, `planet_id`, `power_ids` as
a set) only — never transient browser/session state, which isn't
persisted anywhere. Off by default:

```
ALIEN_SHADOW_READS_ENABLED=true bin/rails server   # root app, with shadow reads on
```

```
ALIEN_SERVICE_URL              default: http://127.0.0.1:3003
ALIEN_SERVICE_OPEN_TIMEOUT     default: 1 (seconds)
ALIEN_SERVICE_READ_TIMEOUT     default: 2 (seconds)
ALIEN_SHADOW_READS_ENABLED     default: false
```

`app/services/aliens/alien_directory.rb` uses a single
`GET /api/v1/aliens` list call for the whole `/aliens` page, regardless of
how many Aliens exist. With all three shadow systems on, visiting
`/aliens` (11 Aliens, 1 Planet, 2 Powers) produces exactly **3**
distributed HTTP calls total — 1 to each service, never per-Alien
fan-out. All three shadow flags can be combined freely; each service's
availability is independent of the others'.
