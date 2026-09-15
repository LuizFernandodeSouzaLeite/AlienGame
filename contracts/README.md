# Inter-service contracts

Explicit contracts between SpaceRails services live here: API documentation,
JSON schemas, and examples for what each domain service exposes over HTTP.

[`worlds/v1/`](worlds/v1/README.md) documents the Planet v1 contract
exposed by World Service (Phase 3). [`powers/v1/`](powers/v1/README.md)
documents the Power v1 contract exposed by Power Service (Phase 7). Alien
Service has no API yet — see
[`docs/architecture/MIGRATION_PLAN.md`](../docs/architecture/MIGRATION_PLAN.md)
for the current phase.

Conventions once contracts start landing here:

```text
contracts/
└── <service>/
    └── v1/
        ├── README.md        (what the service exposes, in prose)
        └── <resource>.schema.json
```
