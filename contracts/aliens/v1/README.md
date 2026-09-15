# Alien Service — v1 contract

Base path: `/api/v1` (Alien Service, default port `3003` in development).
All endpoints are JSON-only: request bodies must be `Content-Type:
application/json`; responses are always `application/json`.

This contract reproduces root's current local Alien validations exactly
(`name` presence only — see `docs/architecture/MIGRATION_PLAN.md`'s Phase
9 compatibility table). Alien Service owns `alien_powers` (ADR-002) — it
is the only service allowed to write that relationship.

## Status

```
GET /api/v1
```

```json
{ "service": "aliens", "version": "v1", "status": "ok" }
```

## Alien resource shape

```json
{
  "id": 7,
  "name": "Zorg",
  "age": 120,
  "planet_id": 1,
  "power_ids": [ 1, 2 ],
  "created_at": "2026-09-14T11:50:01.407Z",
  "updated_at": "2026-09-14T11:50:01.407Z"
}
```

**`planet_id` and `power_ids` are external identifiers**, not embedded
objects:

- `planet_id` refers to a Planet in **World Service**
  (`contracts/worlds/v1/`). Alien Service has no local Planet table and
  no database foreign key to one — existence is validated over HTTP at
  create/update time.
- `power_ids` refers to Powers in **Power Service**
  (`contracts/powers/v1/`). Same validation approach.

A consumer that needs a Planet's name or a Power's name composes it
itself by calling World/Power Service with these ids — Alien Service
never embeds another service's definition data, and never will (ADR-002).

## Endpoints

### `GET /api/v1/aliens`

Returns all aliens. `power_ids` for the whole collection is resolved with
one query against `alien_powers`, not one per Alien.

### `GET /api/v1/aliens/:id`

Returns a single alien. `404` if it doesn't exist.

### `POST /api/v1/aliens`

```json
{ "alien": { "name": "Zorg", "age": 120, "planet_id": 1, "power_ids": [ 1, 2 ] } }
```

`power_ids` is optional (defaults to none). Validates, in order:

1. `name` presence (`422 VALIDATION_ERROR` if blank).
2. `planet_id` exists in World Service (`422 WORLD_NOT_FOUND` if not).
3. Every id in `power_ids` exists in Power Service — checked with **one**
   `GET /api/v1/powers` call, never one per id (`422 POWER_NOT_FOUND`,
   with the specific missing ids, if any don't exist).

If World or Power Service can't be reached to answer (timeout, connection
refusal, 5xx), the whole request fails with `503 DEPENDENCY_UNAVAILABLE`
— it never silently creates an Alien against an unverified reference.

Returns `201 Created` on success.

### `PATCH /api/v1/aliens/:id`

Same body shape as `create`. `power_ids`, if present in the request body,
**entirely replaces** the Alien's relationship set (not a merge) — the
same semantic as assigning `alien.power_ids = [...]` on an ActiveRecord
`has_many :through`. If the `power_ids` key is absent from the request,
existing relationships are left untouched. `planet_id`, if present, is
re-validated against World Service the same way `create` does.

### `DELETE /api/v1/aliens/:id`

Returns `204 No Content`. Removes the Alien and its own `alien_powers`
rows locally — this is no longer a distributed operation (both live in
Alien Service's own database now), unlike Planet/Power deletion, which
still can't reach into Alien Service (see "Known semantic gaps" in
`contracts/worlds/v1/README.md` and `contracts/powers/v1/README.md`).

## Errors

Same envelope shape as World/Power Service's contracts:

```json
{ "error": { "code": "SOME_CODE", "message": "Human-readable message." } }
```

| Code | Status | Meaning |
|---|---|---|
| `ALIEN_NOT_FOUND` | 404 | `:id` doesn't exist |
| `VALIDATION_ERROR` | 422 | local validation failed (`details` has field errors) |
| `WORLD_NOT_FOUND` | 422 | `planet_id` doesn't exist in World Service |
| `POWER_NOT_FOUND` | 422 | one or more `power_ids` don't exist in Power Service (`details.power_ids` lists which) |
| `DEPENDENCY_UNAVAILABLE` | 503 | World or Power Service couldn't be reached to validate the request |

## Known gem-pinning requirement (compatibility pin, not permanent)

`services/aliens/Gemfile` pins `gem "json", "2.21.2"`, for the same reason
documented in `contracts/worlds/v1/README.md` and
`contracts/powers/v1/README.md` — applied proactively here based on the
incident already diagnosed for World Service in Phase 3.
