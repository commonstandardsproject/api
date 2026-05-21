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
      standard_set.ex         -- :map jurisdiction/cspStatus/license (the
                                 adapter remaps embedded `:id` to `_id`,
                                 which would break the wire format), :map
                                 for the standards collection (matches how
                                 the Ruby Hash[id => Standard] is stored)
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
    {resource}_json.ex        -- one response shaper per resource
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

# Run dev server against production read-only Mongo (for parity diffs):
MONGO_READ_ONLY=1 \
  MONGO_URL="mongodb+srv://csp-readonly:..@host/csp-2" \
  mix phx.server
```

### `MONGO_READ_ONLY=1`

Disables the `findAndModify` request-count bump on the auth path so the
server can boot against a read-only replica (e.g. Atlas analytics node).
It's strictly a diagnostic flag — `requestCount` accounting is dropped
while it's set. `config/runtime.exs` raises on boot if it's set alongside
`MIX_ENV=prod`. See `lib/csp_api/users.ex:by_api_key_and_bump/1`.

See `.env.example` for the full set of environment knobs.

## Same-contract testing across both backends

`../contract_tests/` is a language-neutral Python HTTP suite. Aim it at
either the live Ruby app or `mix phx.server` via `CSP_BASE_URL`:

```sh
# Verify the live Ruby API still satisfies the contract
CSP_BASE_URL="https://api.commonstandardsproject.com" \
CSP_API_KEY="..." \
python3 -m pytest ../contract_tests/

# Verify the Phoenix port satisfies the same contract.
# Requires the test-mode endpoint up (JWT bypass on, `Authorization: TEST`
# accepted) and the seed loaded so the read-side tests find their data.
MONGO_URL_TEST=mongodb://localhost:27017/csp-contract-test \
  MIX_ENV=test mix run priv/seed_contract.exs

MONGO_URL_TEST=mongodb://localhost:27017/csp-contract-test \
  PHX_SERVE_TEST=1 MIX_ENV=test mix phx.server &

CSP_BASE_URL="http://localhost:4002" \
  CSP_API_KEY="smoke-key-12345" \
  CSP_ALLOW_WRITES=1 \
  python3 -m pytest ../contract_tests/
```

## Parity diff vs. live Ruby

`scripts/parity_diff.sh` issues the same paths against the running
Phoenix port and live Ruby prod, flattens JSON to `[path, value]` tuples
with `jq`, sorts, and uses `comm` to categorize differences (`extra_null`,
`value_change`, `ruby_only`, `phx_extra`). Requires `MONGO_READ_ONLY=1`
on the Phoenix side so it can boot against the production read-only
replica.

```sh
MONGO_READ_ONLY=1 \
  MONGO_URL="mongodb+srv://csp-readonly:..@host/csp-2" \
  mix phx.server &

CSP_API_KEY=... ./scripts/parity_diff.sh \
  /api/v1/jurisdictions \
  /api/v1/jurisdictions/MD \
  /api/v1/standard_sets/MD_D1_grade-01 \
  /sitemap.xml
```
