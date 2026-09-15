# ADR-002: Domain Service Boundaries

## Status

**Accepted in full.** Both sub-decisions below (`alien_powers` ownership and
the `Planet.dependent: :destroy` cascade) were reviewed and closed by the
human owner after Phase 1. Their resolutions are recorded as APPROVED
decisions, not open questions.

## Approved domain ownership

```text
World Service
  owns Planet / World domain data.

Alien Service
  owns Alien domain data.
  owns alien_powers relationship data.

Power Service
  owns Power definitions/catalog.

Planet deletion keeps its current cascade semantic (deleting a Planet still
implies its Aliens go with it), but the final distributed implementation of
that cascade is deferred until Alien Service is actually extracted (Phase 9+).
```

## Context

The current codebase (audited directly, not assumed) has exactly these
cross-domain touch points:

```text
Alien  → Planet   belongs_to :planet            (alien.planet_id, NOT NULL)
Planet → Alien     has_many :aliens, dependent: :destroy
Alien  → Power     has_many :powers, through: :alien_powers
Power  → Alien     has_many :aliens, through: :alien_powers
```

Views that currently walk these associations directly:
`app/views/aliens/_dossier.html.erb`, `_workstation.html.erb`,
`_drawer.html.erb`, `_form.html.erb`, `app/views/shared/_record.html.erb`.
Controllers: `AliensController#index`/`#show` (`Alien.includes(:planet,
:powers)`), `alien_params` accepts `power_ids: []`.

Current data (recorded as the Phase-0 baseline, see the migration plan):
1 Planet, 11 Aliens, 2 Powers, 10 `alien_powers` rows.

## Decision

```text
WORLD DOMAIN            → World Service
  Planet
  planet CRUD / validation
  (future: generation, environment, geology, biosphere)

ALIEN DOMAIN             → Alien Service
  Alien
  alien CRUD / validation
  specimen profile generation (SpecimenProfile)
  the alien_powers join (see below — NEEDS PRODUCT REVIEW)

POWER DOMAIN              → Power Service
  Power
  power CRUD / validation
  (future: affinity / influence calculation)

WEB / SHARED EXPERIENCE   → SpaceRails Web
  navigation, facility shell, Turbo/Stimulus, Three.js Universe Engine
  composes World/Alien/Power data into the existing UI, unchanged
```

`Planet` keeps its Ruby class name. The *service* is called World Service;
nothing in code is renamed to `World` without a separate, explicit product
decision (per the migration prompt's own rule against renaming during an
architecture pass).

### APPROVED — `alien_powers` ownership

**Decision: Alien Service owns `alien_powers`.**

Rationale: Power Service owns the *definition and catalog* of Powers. Alien
Service owns the *biological/entity-level fact* that a specific Alien
possesses or references one or more Powers — that fact reads as alien-domain
data ("what this specimen can do"), matching how the UI already presents it
(`_dossier.html.erb`'s "REGISTERED ABILITY" field lives next to the
specimen, not the power).

Target distributed model:

- Alien Service stores `alien_powers` rows with an *external* `power_id`
  (no DB-level FK — Power lives in another database).
- Alien Service MUST NOT directly query Power Service's database, and
  Power Service MUST NOT directly query Alien Service's database — no
  cross-service database foreign key exists in the final architecture.
- If Alien needs Power information (name, etc.) it goes through Power
  Service's contract/API (batched lookup, not N+1 — ADR-004), or an
  explicitly approved local projection/cache introduced later.

The rejected alternative (Power Service owning the join instead) was ruled
out: it would make Power Service depend on Alien identifiers for no domain
reason, and the "Register Power" form has no concept of aliens today.

**Not implemented yet.** This decision governs Phase 9 (Alien Service
extraction). Phase 2 (World Service skeleton) does not touch `alien_powers`.

### APPROVED WITH SEMANTIC PRESERVATION — the `Planet.dependent: :destroy` cascade

**Decision: the product semantic is preserved — deleting a Planet still
implies its Aliens are removed with it. Only the *implementation mechanism*
changes, and only once there are two real sides of the boundary to
orchestrate.**

Target SOA semantics (conceptual, not implemented yet):

```text
DELETE PLANET REQUEST
        ↓
World Service validates deletion
        ↓
Alien Service is instructed to remove/process Aliens belonging to that Planet
        ↓
result is confirmed
        ↓
World Service completes Planet deletion
```

The exact orchestration mechanism (synchronous HTTP call, async domain
event, saga/process manager) is **not decided yet** — it depends on
requirements discovered when Alien Service actually exists. This ADR commits
only to: no cross-service database foreign key, no shared ActiveRecord
model, no service reaching directly into another service's database to
perform the cascade.

**Current migration rule, binding through Phase 8:**

- Do NOT remove or replace `dependent: :destroy` while Alien still lives in
  the current Rails application (i.e. through Phase 2–8).
- Do NOT implement the distributed cascade yet — there is nothing to
  orchestrate with until Alien Service exists.
- Planet deletion behavior is byte-for-byte unchanged until Alien Service is
  extracted (Phase 9), at which point this becomes a dedicated migration
  concern of its own.

### APPROVED WITH SEMANTIC PRESERVATION — the `Power.dependent: :destroy` cascade

**Added during Phase 7 (Power Service extraction), on the same evidence-based
basis as the Planet cascade above — not a new open question.** Root's
`Power.dependent: :destroy` cascades to `alien_powers` (proven by test:
`test/models/power_alien_powers_coupling_test.rb`, root app — deleting a
Power removes exactly the `alien_powers` rows referencing it, leaving Alien
rows untouched). Power Service's own `DELETE /api/v1/powers/:id` cannot
reach `alien_powers` — that table lives in root's database today and
Alien Service's database after extraction, and Power Service must never
open another service's database (ADR-003).

Same resolution as the Planet cascade: the product semantic (deleting a
Power removes its `alien_powers` associations) is preserved conceptually;
only the implementation becomes a distributed concern, deferred until
Alien Service exists to be the other side of that orchestration. Same
binding rule: do not remove or replace `Power`'s `dependent: :destroy` in
root while Alien still lives in the current Rails application, and do not
implement a distributed version until Phase 9+.

## Consequences

Both boundary questions are now closed decisions, not open risks. World
Service extraction (Phase 2+) can proceed for Planet's full CRUD, `destroy`
included, with `dependent: :destroy` left exactly as it is today for as long
as Alien remains part of the monolith.
