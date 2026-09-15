# ADR-005: Monorepo, Not Multi-Repo

## Status

Accepted.

## Decision

All services and the web app live in **one repository**:

```text
spacerails/
├── web/                  (eventually — see "deferred" below)
├── services/
│   ├── worlds/
│   ├── aliens/
│   └── powers/
├── contracts/
├── docs/architecture/
└── (root tooling / CI)
```

Monorepo ≠ monolith. Each directory under `services/` is independently
bootable, independently testable, and independently deployable — the
monorepo is a coordination choice, not an architecture regression back to
"one big app."

## Why monorepo, specifically now

- Coordinated review: a change to the `alien_powers` boundary (ADR-002)
  touches both Alien and Power service code in one PR, reviewable as one
  unit, instead of a cross-repo release dance for a two-person project.
- Simpler local development: one `git clone`, one place to run `bin/dev` /
  the future equivalent, instead of juggling four repositories at matching
  commits.
- SpaceRails is not yet organizationally split into separate teams per
  service. Multi-repo overhead (versioned inter-repo dependencies, separate
  CI per repo, separate issue trackers) buys nothing at this stage and would
  actively slow the migration down.

## Physical location of the web app during migration

**The current Rails application stays at the repository root while services
are extracted.** It is not moved into `web/` as part of Phase 1 or as a
prerequisite for extracting World/Power/Alien. Moving it is deferred to
Phase 11 (after all three services are stable) specifically so a folder
rename never gets confused with an actual architecture change, per the
migration's own "physical separation ≠ architectural separation" rule. If
moving it later turns out to be disproportionately risky for the benefit, it
stays at the root and that deferral gets documented — folder aesthetics never
outrank working software.

## Consequences

- `services/worlds`, `services/aliens`, `services/powers` will each need
  their own `Gemfile`, `config/database.yml`, `bin/rails`, test suite, and
  CI job — this is real duplication of Rails boilerplate, accepted as the
  cost of genuine independence (a shared `Gemfile` across services would
  reintroduce exactly the coupling this migration exists to remove).
- CI must be able to scope a run to "only what changed" (`services/worlds/**`
  → only World's tests) rather than always running everything — tracked as
  Phase 2+ CI work, not solved in this documentation-only pass.
