# frontend

Reserved for the Common Standards Project frontend.

This folder is a placeholder in the `platform` monorepo. The frontend
application has not been migrated in yet. When it lands, it should be a
self-contained app (its own `package.json`, build tooling, and
`Dockerfile`) so it can be built and deployed independently of — or
alongside — the [`backend/`](../backend) service.

## Northflank

Each deployable app in this monorepo is its own Northflank service that
builds from this same Git repository, distinguished by its **build
context** and **Dockerfile path**:

| Service  | Build context | Dockerfile           |
| -------- | ------------- | -------------------- |
| backend  | `/backend`    | `/backend/Dockerfile` |
| frontend | `/frontend`   | `/frontend/Dockerfile` (TBD) |

See the root [`README.md`](../README.md) and
[`backend/README.md`](../backend/README.md) for deploy details.
