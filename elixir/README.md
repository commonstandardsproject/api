# CSP API (Elixir/Phoenix/Ecto)

Phoenix port of the Ruby/Grape CSP API. Talks to MongoDB through Ecto via
the `mongodb_ecto` adapter — same data store, full Ecto schemas +
changesets at the boundary.

## Layout

```
lib/
  csp_api/
    application.ex            -- starts Repo + Phoenix
    repo.ex                   -- Ecto.Repo, adapter: Mongo.Ecto
    mongo_x.ex                -- escape hatch for nested-field filters
                                 (Mongo.Ecto.command/2 around `find`)
    schemas/                  -- Ecto.Schema modules
      jurisdiction.ex
      standard_set.ex         -- embeds_one jurisdiction/cspStatus/license,
                                 :map for the standards collection (matches
                                 how the Ruby Hash[id => Standard] is stored)
      user.ex
      activity.ex
      pull_request.ex         -- embeds_many activities, :map standardSet
    jurisdictions.ex          -- context (Repo.all/get + MongoX for joins)
    standard_sets.ex          -- context (Repo.get + Hierarchy walk)
    users.ex                  -- context (findAndModify upsert for atomicity)
    pull_requests.ex          -- create_blank/create_forked/change_status
    hierarchy.ex              -- port of lib/standard_hierarchy.rb
    id.ex                     -- UUID.uuid4 |> strip-hyphens |> upcase
    email.ex                  -- pluggable mailer (test adapter built in)
  csp_api_web/
    endpoint.ex
    router.ex
    plugs/
      api_key_auth.ex         -- Api-Key → current_user (keeps Ruby's
                                 missing-header behavior)
      jwt_auth.ex             -- Auth0 JWT; `Authorization: TEST` bypass
                                 gated on :auth, :jwt_test_bypass? (only
                                 set in config/test.exs)
    controllers/              -- one per resource
    json.ex                   -- single module of response shapers
test/
  csp_api/
    hierarchy_test.exs        -- pure unit test for the ancestor walk
    schemas/
      standard_set_test.exs   -- changeset validations
      pull_request_test.exs   -- changeset validations
  csp_api_web/controllers/    -- in-process Phoenix controller tests
  support/
    data_case.ex              -- per-test Repo reset (with safety belt)
    conn_case.ex              -- adds an authed Plug.Conn
    fixtures.ex               -- Repo.insert via changesets
```

## Running

Requires a local MongoDB. Test runs use a separate database whose name
must contain the substring `test`; `test/test_helper.exs` refuses to start
otherwise.

```sh
mix deps.get

# Pure unit tests (no Mongo needed):
mix test test/csp_api/hierarchy_test.exs test/csp_api/schemas/

# Full suite (requires local Mongo):
mix test

# Run dev server against production read-only Mongo:
MONGO_URL="mongodb+srv://csp-readonly:..@host/csp-2" mix phx.server
```

## Same-contract testing across both backends

`../contract_tests/` is a language-neutral Python HTTP suite. Aim it at
either the live Ruby app or `mix phx.server` via `CSP_BASE_URL`:

```sh
# Verify the live Ruby API still satisfies the contract
CSP_BASE_URL="https://api.commonstandardsproject.com" \
CSP_API_KEY="..." \
python3 -m pytest ../contract_tests/

# Verify the Phoenix port satisfies the same contract
CSP_BASE_URL="http://localhost:4000" \
CSP_API_KEY="..." \
python3 -m pytest ../contract_tests/

# Include write-side tests (pull requests, users)
CSP_ALLOW_WRITES=1 ... python3 -m pytest ../contract_tests/
```
