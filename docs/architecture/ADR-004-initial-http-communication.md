# ADR-004: HTTP/REST Now, Domain Events Later

## Status

Accepted.

## Decision

Inter-service communication starts as **HTTP/REST**, versioned from day one:

```text
GET  /api/v1/planets
GET  /api/v1/planets/:id
GET  /api/v1/powers
GET  /api/v1/powers/:id
POST /api/v1/powers/batch_lookup   (ids: [...]) → avoids N+1 over HTTP
```

No Kafka, RabbitMQ, NATS, Redis Streams, gRPC, or service mesh is introduced
in this migration. Nothing in the current codebase demands it.

## Service clients

All outbound HTTP calls from SpaceRails Web live behind explicit client
objects — never scattered `Net::HTTP`/`Faraday` calls in controllers, views,
or helpers:

```text
app/clients/worlds_client.rb
app/clients/powers_client.rb
app/clients/aliens_client.rb   (once Alien is extracted)
```

Each client:

- reads its target base URL from configuration/environment
  (`WORLD_SERVICE_URL`, `POWER_SERVICE_URL`, `ALIEN_SERVICE_URL` —
  ADR-per environment, never a hardcoded `"http://localhost:3001"`),
- sets an explicit **open timeout and read timeout** (no indefinite waits),
- raises a small, typed error on failure (`WorldsClient::Unavailable`,
  `WorldsClient::NotFound`) that callers handle deliberately — never a bare
  `nil` standing in for "the service was down".

## Error contract

Every service's API responds to failures with the same envelope shape:

```json
{ "error": { "code": "PLANET_NOT_FOUND", "message": "Planet could not be found." } }
```

Internal Rails stack traces are never exposed through these endpoints
(`config.consider_all_requests_local = false` in the relevant environments,
already Rails' own default outside development).

## N+1 over HTTP

The existing `AliensController#index` already does
`Alien.includes(:planet, :powers)` specifically to avoid N+1 SQL. The service
split must not regress that into "11 aliens → 11 HTTP calls to World
Service". Once Alien Service needs planet/power names for a list of aliens,
it calls the batched lookup endpoint once, not once per row.

## What this ADR defers, on purpose

- A message broker / event bus, for when `WorldEnvironmentGenerated →
  AlienAdaptationCalculated`-style cross-domain reactions actually exist
  (they don't yet — no planetary generation is implemented).
- An API gateway — three services and one web app do not need one yet.
- A distributed cache (Redis) — not introduced merely because there are now
  multiple processes.
- Circuit breakers / retries with backoff — timeouts + a clear error is
  enough at this scale; document today's simpler failure mode below instead
  of building resilience infrastructure nothing yet requires.

## Failure mode (documented, not engineered around yet)

If World Service is down and Web needs Planet data: the request fails fast
(timeout), the client raises `WorldsClient::Unavailable`, and the controller
renders a clear "the planetary registry is unreachable" state — never a
silent empty list pretending there are no planets, never an indefinite hang.
