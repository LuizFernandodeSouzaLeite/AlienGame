# World Service — v1 contract

**Consumers:** as of Phase 5, root SpaceRails' `WorldsClient`
(`app/clients/worlds_client.rb`) consumes `GET /api/v1/planets` and
`GET /api/v1/planets/:id` for shadow-read verification only — see
`docs/architecture/MIGRATION_PLAN.md`'s Phase 5 record. No write endpoint
is consumed by root yet.

Base path: `/api/v1` (World Service, default port `3001` in development).
All endpoints are JSON-only: request bodies must be `Content-Type:
application/json`; responses are always `application/json`.

This contract reproduces the current root SpaceRails `Planet` domain
exactly — see `docs/architecture/MIGRATION_PLAN.md`'s compatibility table.
It does not add validations, associations, or fields beyond what root's
`Planet` model has today. In particular:

- `name` has no presence validation. A blank name is a valid Planet.
- There is no `Alien`/`Power` association here — World Service owns only
  the World domain (see ADR-002 for why `alien_powers`/cascade-delete
  ownership questions are resolved elsewhere).
- `destroy` only ever deletes the row in World's own database. It does not
  cascade to anything, because nothing in this service depends on it.

## Status

```
GET /api/v1
```

Returns service identity/liveness. Not part of the Planet resource proper.

```json
{ "service": "worlds", "version": "v1", "status": "ok" }
```

## Planet resource shape

Returned by `show`, `create`, `update`, and as each element of `index`'s
`data` array:

```json
{
  "id": 1,
  "name": "Kepler-9c",
  "created_at": "2026-09-15T13:18:54.509Z",
  "updated_at": "2026-09-15T13:18:54.509Z"
}
```

Exactly these four fields — see
`services/worlds/test/contracts/planet_v1_contract_test.rb`, which pins
this shape.

## Endpoints

### `GET /api/v1/planets`

Returns all planets.

```json
{ "data": [ { "id": 1, "name": "Kepler-9c", "created_at": "...", "updated_at": "..." } ] }
```

### `GET /api/v1/planets/:id`

Returns a single planet. `404` (see Errors) if it doesn't exist.

### `POST /api/v1/planets`

Request body:

```json
{ "planet": { "name": "Kepler-9c" } }
```

Unknown attributes inside `planet` are silently ignored (only `name` is a
permitted attribute). Returns `201 Created` with the Planet shape. Since
`name` has no presence validation, `{ "planet": { "name": "" } }` also
succeeds with `201`.

### `PATCH /api/v1/planets/:id`

Same request shape as `create`. Returns `200 OK` with the updated Planet.

### `DELETE /api/v1/planets/:id`

Returns `204 No Content` with an empty body. Idempotent only in the sense
that it errors (`404`) on a second call, same as `show`.

## Errors

All error responses share one envelope shape:

```json
{ "error": { "code": "SOME_CODE", "message": "Human-readable message." } }
```

### `404 Not Found` — `PLANET_NOT_FOUND`

Returned by `show`, `update`, `destroy` when `:id` doesn't exist.

```json
{ "error": { "code": "PLANET_NOT_FOUND", "message": "Planet could not be found." } }
```

### `422 Unprocessable Content` — `VALIDATION_ERROR`

Returned by `create`/`update` if a save fails. The error envelope gains a
`details` key (ActiveRecord's `errors.to_hash`) alongside `code`/`message`:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Planet could not be saved.",
    "details": { "name": [ "can't be blank" ] }
  }
}
```

Root's `Planet` currently has no validations that can fail, so this path
is not reachable today — it is documented and contract-pinned
(`test/contracts/planet_v1_contract_test.rb`) so the envelope shape exists
before it's ever exercised for real.

## Known gem-pinning requirement (compatibility pin, not permanent)

`services/worlds/Gemfile` pins `gem "json", "2.21.2"` to match root. This is
a **compatibility pin** tied to the current Rails 8.1.3.1/ActiveSupport
combination, not a permanently required version. If Rails/ActiveSupport or
the `json` gem changes in a way that resolves the underlying incompatibility
(see below), this pin should be reevaluated — but only for root and World
Service together, never updated on one side in isolation. A
fresh `bundle install` without that pin resolves `json` to `3.x`, which
breaks `ActiveSupport::JSON.decode`'s call into `::JSON.parse` for any
request with a real (non-form-encoded) JSON body — every endpoint above
that accepts a body would 400 with `ActionDispatch::Http::Parameters::ParseError`.
Do not remove this pin without re-verifying real JSON request bodies work,
not just Rails' test-helper `params:` hash (which is form-encoded and does
not exercise this code path).
