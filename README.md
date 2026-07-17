# Common Standards Project — platform

Monorepo for the Common Standards Project. Each top-level folder is an
independently buildable, independently deployable application.

```
platform/
├── backend/         Elixir / Phoenix API (the CSP API)
├── frontend/        Web frontend (placeholder — not yet migrated)
└── contract_tests/  Language-neutral black-box HTTP contract suite
```

- **`backend/`** — the Phoenix/Ecto port of the CSP API, backed by
  MongoDB. This is the service that replaces the old Ruby/Sinatra app.
  See [`backend/README.md`](backend/README.md).
- **`frontend/`** — reserved for the frontend app. See
  [`frontend/README.md`](frontend/README.md).
- **`contract_tests/`** — HTTP contract tests that can run against any
  deployment of the API (local, staging, or production). See
  [`contract_tests/README.md`](contract_tests/README.md).

## Deploying to Northflank

We deploy on [Northflank](https://northflank.com), building each app
directly from this Git repository
([build from a Git repository](https://northflank.com/docs/v1/application/build/build-code-from-a-git-repository)).
Because this is a monorepo, each service points at the **same repo** but a
different **build context** and **Dockerfile**:

| Service  | Build context | Dockerfile            | Container port |
| -------- | ------------- | --------------------- | -------------- |
| backend  | `/backend`    | `/backend/Dockerfile` | `4000`         |
| frontend | `/frontend`   | `/frontend/Dockerfile`| _TBD_          |

### backend service — Northflank settings

Create a **Combined Service** (build + deploy) from this repository:

1. **Build**
   - Build type: **Dockerfile**
   - Repository: `commonstandardsproject/platform`, branch `main`
   - **Build context directory:** `/backend`
   - **Dockerfile path:** `/backend/Dockerfile`

   The Dockerfile is a standard two-stage Elixir release build (compile in
   `hexpm/elixir`, run on slim Debian). No build args are required.

2. **Networking**
   - Add a public port on **`4000`**, protocol HTTP.
   - **Health check:** HTTP `GET /healthz` on port `4000`. This is a pure
     liveness endpoint — it returns `200` without touching Mongo.

3. **Runtime environment variables**

   Required (the release refuses to boot without these — see
   [`backend/config/runtime.exs`](backend/config/runtime.exs)):

   | Variable                 | Notes                                                         |
   | ------------------------ | ------------------------------------------------------------- |
   | `MONGO_URL`              | e.g. `mongodb+srv://user:pass@host/db?appName=production`. TLS is auto-configured for `+srv` URLs. |
   | `SECRET_KEY_BASE`        | Generate with `mix phx.gen.secret` (64+ bytes).               |
   | `AUTH0_CLIENT_ID`        | Auth0 application client id.                                  |
   | `AUTH0_CLIENT_SECRET`    | Used to validate the JWT.                                     |
   | `ALGOLIA_APPLICATION_ID` | Search index credentials.                                     |
   | `ALGOLIA_API_KEY`        | Search index credentials.                                     |
   | `POSTMARK_API_TOKEN`     | Transactional email (PR status-change notifications).         |
   | `POSTMARK_FROM_ADDRESS`  | Verified Postmark sender address.                             |

   Optional:

   | Variable          | Default                     | Notes                                    |
   | ----------------- | --------------------------- | ---------------------------------------- |
   | `PORT`            | `4000`                      | Northflank injects this; the app honors it. |
   | `PHX_HOST`        | `localhost`                 | Public hostname, used to build URLs.     |
   | `MONGO_POOL_SIZE` | `10`                        | Mongo connection pool size.              |
   | `ALGOLIA_INDEX`   | `common-standards-project`  | Algolia index name.                      |

   Do **not** set `MONGO_READ_ONLY` in production — the release refuses to
   boot with it under `MIX_ENV=prod`.

The image runs `MIX_ENV=prod`. `PORT` from Northflank is respected, the
endpoint binds `0.0.0.0`, and the release starts with `bin/csp_api start`.

### Building the image locally

```sh
docker build -t csp-backend backend/
docker run --rm -p 4000:4000 \
  -e SECRET_KEY_BASE="$(openssl rand -base64 48)" \
  -e MONGO_URL="mongodb://host.docker.internal:27017/csp" \
  # ...plus the other required vars above...
  csp-backend
curl localhost:4000/healthz   # -> 200
```

## What is this?

API and tooling for the Common Standards Project — a database of academic
standards from all 50 US states, plus organizations, districts, and
schools. Live API: <https://api.commonstandardsproject.com>. Project site:
<https://commonstandardsproject.com>.

## CI

[`.github/workflows/backend.yml`](.github/workflows/backend.yml) runs
`mix test` plus the Python contract suite against a throwaway Mongo, on any
change under `backend/**` or `contract_tests/**`.
