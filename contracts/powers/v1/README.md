# Power Service — v1 contract

**Consumers:** as of Phase 8, root SpaceRails' `PowersClient`
(`app/clients/powers_client.rb`) consumes `GET /api/v1/powers` and
`GET /api/v1/powers/:id` for shadow-read verification only — see
`docs/architecture/MIGRATION_PLAN.md`'s Phase 8 record. No write endpoint
is consumed by root yet. The consumer only ever verifies Power
*definitions* (`id`/`name`); it has no concept of and never asks about
`alien_powers`.

Base path: `/api/v1` (Power Service, default port `3002` in development).
All endpoints are JSON-only: request bodies must be `Content-Type:
application/json`; responses are always `application/json`.

This contract reproduces the current root SpaceRails `Power` domain
exactly — see `docs/architecture/MIGRATION_PLAN.md`'s Phase 7
compatibility table. It does not add validations or fields beyond what
root's `Power` model has today. In particular:

- `name` has no presence validation. A blank name is a valid Power.
- There is no `Alien` model or `alien_powers` relationship here — Power
  Service owns only the Power *definition/catalog*. The fact that a given
  Alien possesses a given Power belongs to Alien Service (ADR-002); this
  service never stores or exposes that relationship.
- `destroy` only ever deletes the row in Power Service's own database. It
  does not, and architecturally cannot, cascade to `alien_powers` —
  see "Known semantic gap" below.

## Status

```
GET /api/v1
```

Returns service identity/liveness. Not part of the Power resource proper.

```json
{ "service": "powers", "version": "v1", "status": "ok" }
```

## Power resource shape

Returned by `show`, `create`, `update`, and as each element of `index`'s
`data` array:

```json
{
  "id": 1,
  "name": "Fire",
  "created_at": "2026-09-14T11:50:01.407Z",
  "updated_at": "2026-09-14T11:50:01.407Z"
}
```

Exactly these four fields — see
`services/powers/test/contracts/power_v1_contract_test.rb`, which pins
this shape.

## Endpoints

### `GET /api/v1/powers`

Returns all powers.

### `GET /api/v1/powers/:id`

Returns a single power. `404` (see Errors) if it doesn't exist.

### `POST /api/v1/powers`

Request body:

```json
{ "power": { "name": "Fire" } }
```

Unknown attributes inside `power` are silently ignored (only `name` is a
permitted attribute). Returns `201 Created`. Since `name` has no presence
validation, `{ "power": { "name": "" } }` also succeeds with `201`.

### `PATCH /api/v1/powers/:id`

Same request shape as `create`. Returns `200 OK` with the updated Power.

### `DELETE /api/v1/powers/:id`

Returns `204 No Content`.

## Errors

Same envelope shape as World Service's contract:

```json
{ "error": { "code": "SOME_CODE", "message": "Human-readable message." } }
```

### `404 Not Found` — `POWER_NOT_FOUND`

```json
{ "error": { "code": "POWER_NOT_FOUND", "message": "Power could not be found." } }
```

### `422 Unprocessable Content` — `VALIDATION_ERROR`

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Power could not be saved.",
    "details": { "name": [ "can't be blank" ] }
  }
}
```

Root's `Power` currently has no validations that can fail, so this path
is not reachable today — documented and contract-pinned the same way as
World's equivalent.

## Known semantic gap: Power deletion and `alien_powers`

**Proven current root behavior** (see the Phase 7 migration record):
deleting a root `Power` cascades, via `dependent: :destroy`, to every
`alien_powers` row referencing it — the Alien rows themselves are
untouched, only the join rows are removed.

`DELETE /api/v1/powers/:id` exists on this service and deletes the Power
row — but it has **no way to reach the `alien_powers` table**, which
lives in root's database today and will live in Alien Service's database
after extraction (ADR-002/ADR-003: Power Service must never open another
service's database). This means: **the API exists, but full semantic
parity with root's current delete behavior is not complete until Alien
Service exists and a cross-service cleanup workflow is designed for it**
— the same kind of distributed-cascade deferral ADR-002 already commits
to for `Planet#destroy` → Aliens. This is not implemented in Phase 7 and
is not claimed to be.

## Known gem-pinning requirement (compatibility pin, not permanent)

`services/powers/Gemfile` pins `gem "json", "2.21.2"` to match root, for
the same reason documented in `contracts/worlds/v1/README.md`: a fresh
`bundle install` without this pin resolves `json` to `3.x`, which breaks
`ActiveSupport::JSON.decode`'s call into `::JSON.parse` for any request
with a real (non-form-encoded) JSON body. Applied here proactively during
Phase 7, based on the incident already documented for World Service in
Phase 3 — confirmed via real curl QA with `Content-Type: application/json`
bodies on every endpoint, not just the test suite's form-encoded helper.
