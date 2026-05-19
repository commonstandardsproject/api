# CSP API (Elixir/Phoenix)

Elixir/Phoenix port of the Ruby/Grape Common Standards Project API. The data
layer still talks to MongoDB through `:mongodb_driver`; the rest is plain
Phoenix.

## Layout

```
lib/
  csp_api/                 -- domain contexts
    application.ex         -- starts Mongo + Phoenix + PubSub
    mongo.ex               -- thin facade over the driver
    jurisdictions.ex       -- read ops on `jurisdictions`
    standard_sets.ex       -- read + upsert on `standard_sets`
    pull_requests.ex       -- PR creation/edit/status change
    users.ex               -- user upsert/lookup
    hierarchy.ex           -- adds parentId/ancestorIds (lib/standard_hierarchy.rb port)
    id.ex                  -- csp_uuid + base58 token helpers
    email.ex               -- pluggable mailer (test adapter in test/)
  csp_api_web/
    endpoint.ex
    router.ex
    plugs/
      api_key_auth.ex      -- API-Key header → current_user
      jwt_auth.ex          -- Auth0 JWT verification (with `Authorization: TEST` bypass in env=test)
    controllers/
    json/                  -- response shapers (replace Grape entities)
test/
  csp_api/
    hierarchy_test.exs     -- pure unit test for the ancestor algorithm
  csp_api_web/controllers/ -- in-process controller tests against the router
  support/
    conn_case.ex           -- per-test Mongo cleanup + auth setup
    fixtures.ex            -- minimal inserters for jurisdictions/standard_sets
```

## Running

A local MongoDB is required for the in-process tests.

```sh
# get deps
mix deps.get

# run the full Elixir test suite (controller tests + hierarchy unit tests)
mix test

# run only the hierarchy unit test (no Mongo needed)
mix test test/csp_api/hierarchy_test.exs

# start a dev server
MONGO_URL="mongodb+srv://user:pass@host/csp-2" mix phx.server
```

## Cross-backend contract tests

A language-neutral Python contract suite lives at
`../contract_tests/`. It accepts a `CSP_BASE_URL` env var so you can run the
exact same assertions against either backend:

```sh
# Validate the live Ruby API
CSP_BASE_URL="https://api.commonstandardsproject.com" \
CSP_API_KEY="..." \
python3 -m pytest ../contract_tests/

# Validate the local Phoenix port
CSP_BASE_URL="http://localhost:4000" \
CSP_API_KEY="..." \
python3 -m pytest ../contract_tests/
```

Write-side tests (pull requests, users) are gated behind `CSP_ALLOW_WRITES=1`
and are not run against the live API by default.
