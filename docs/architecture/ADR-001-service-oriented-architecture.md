# ADR-001: Adopt a Service-Oriented Architecture

## Status

Accepted (Phase 0/1 — documentation only; no extraction has happened yet).

## Context

SpaceRails is currently a single Rails 8.1 application (SQLite, server-rendered
views, Turbo/Stimulus, a persistent Three.js "Universe Engine") that owns three
domains — `Alien`, `Planet`, `Power` — in one database, one codebase, one
deployable unit.

The product is expected to grow along three largely independent fronts:

- **World** (planets): future planetary generation, environment, geology,
  biosphere.
- **Alien** (xenobiology): the specimen engine, procedural morphology and
  behavior, the containment-chamber experience.
- **Power** (energy/abilities): future affinity and influence calculations.

These fronts have different rates of change and, eventually, different
ownership. Keeping them in one undifferentiated Rails app makes it hard to:

- reason about which code is allowed to touch which data;
- let each domain evolve (and eventually deploy) on its own schedule;
- prevent accidental coupling (a view quietly doing `alien.planet.aliens...`).

## Decision

Move to a **Service-Oriented Architecture** with **coarse-grained domain
services**:

- **World Service** — owns `Planet`.
- **Power Service** — owns `Power`.
- **Alien Service** — owns `Alien` (and the `alien_powers` join data — see
  ADR-002).
- **SpaceRails Web** — owns the user-facing experience (HTML composition,
  Turbo/Stimulus, the Universe Engine, the Xenobiology Laboratory visuals) and
  talks to the domain services over HTTP.

Communication starts as **HTTP/REST** (ADR-004). No message broker, no
event bus, no additional language runtime. Repository stays a **monorepo**
(ADR-005).

## Consequences

**Benefits**

- Explicit ownership: a service either owns its data or it doesn't touch it.
- Independent testability: `test worlds`, `test aliens`, `test powers`,
  `test web` become meaningful, separate commands.
- A path to independent deployment later, without committing to it now.

**Costs — stated plainly, not hidden**

- Network calls replace in-process method calls (`alien.planet` becomes an
  HTTP round trip through a client object).
- Distributed debugging is harder than a single stack trace.
- Cross-service data (an Alien's `planet_id`, the `alien_powers` join) can no
  longer be enforced by a database foreign key across services — see ADR-003.
- More moving parts to boot locally (three services + web instead of one
  `bin/rails server`).
- Eventual consistency becomes possible wherever a cascade (e.g. "deleting a
  planet deletes its aliens") crosses a service boundary. This SpaceRails
  currently relies on `dependent: :destroy` for that specific case, and this
  decision **breaks that mechanism** — see ADR-002 for the resolution
  required before Alien is actually extracted.

These costs are accepted because the product's roadmap (planetary generation
feeding alien evolution feeding power affinity — see ADR-005 in the earlier
`Guia.md` — is drawn as three fronts on purpose) benefits more from clear
boundaries now than from staying monolithic and re-untangling this later
under time pressure.
