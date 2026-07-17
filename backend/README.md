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

### Read-side: `scripts/parity_diff.sh`

Issues the same paths against the running Phoenix port and live Ruby
prod, flattens JSON to `[path, value]` tuples with `jq`, sorts, and uses
`comm` to categorize differences (`extra_null`, `value_change`,
`ruby_only`, `phx_extra`). Requires `MONGO_READ_ONLY=1` on the Phoenix
side so it can boot against the production read-only replica.

```sh
MONGO_READ_ONLY=1 \
  MONGO_URL="mongodb+srv://csp-readonly:..@host/csp-2" \
  mix phx.server &

CSP_API_KEY=... ./scripts/parity_diff.sh \
  /api/v1/jurisdictions \
  /api/v1/jurisdictions/MD \
  /api/v1/standard_sets/MD_D1_grade-01 \
  /api/v1/sitemap.xml
```

### Building a representative corpus

`scripts/build_parity_corpus.sh` walks the running Phoenix port to
synthesize a ~250-URL corpus covering listings, every major
jurisdiction type, a slice of standard sets (including
`?standardsAsArray=true`), and a handful of standard documents. Pipe
its output into `parity_diff.sh`:

```sh
CSP_API_KEY=... ./scripts/build_parity_corpus.sh > /tmp/corpus.txt
CSP_API_KEY=... ./scripts/parity_diff.sh $(< /tmp/corpus.txt)
```

Last run (2026-05-21, 249 paths): **242/249 byte-clean**. The 6 that
return `status: ruby=500 phx=200` are a long-standing Ruby bug — the
`/standard_documents/:id` endpoint references the non-existent
`Entities::StandardsDocument` (extra `s`) and crashes on every hit;
Phoenix returns valid JSON. The 7th non-clean path is `/swagger_doc`,
which is out of scope per the maintainer (grape-swagger vs OpenApiSpex).

### Write-side: `scripts/post_parity_diff.sh`

Drives `create_blank → user_update → comment → submit →
change_status(rejected)` against two backends pointed at separate
databases, then diffs the response bodies (after stripping non-
deterministic fields: ids, timestamps, asanaTaskId, pullRequestUrl).

Latest run (2026-05-21): **6/6 endpoints byte-clean** with parallel
`parity-ruby` / `parity-phx` Mongo databases.

```sh
# 1. Seed two parallel databases with the same fixtures (matching ids
#    so the diff sees identical inputs).
mongosh -u admin -p admin --eval '
  ["parity-ruby", "parity-phx"].forEach(name => {
    const d = db.getSiblingDB(name);
    d.dropDatabase();
    d.users.insertOne({_id:"PARITY_COMMITTER",apiKey:"parity-test-key",isCommitter:true,profile:{name:"Parity Tester"},email:"parity@test.com"});
    d.jurisdictions.insertOne({_id:"PARITY",title:"Parity Jurisdiction",type:"state",status:"approved"});
    d.standard_sets.insertOne({_id:"PARITY_TEST_SET",title:"Parity Test",subject:"Math",educationLevels:["01"],jurisdiction:{id:"PARITY",title:"Parity Jurisdiction"},document:{id:"PARITY_DOC"},standards:{S1:{id:"S1",depth:0,position:1,description:"only standard"}},standardsCount:1,version:1});
  });'

# 2. Boot the Ruby app against parity-ruby, with ENVIRONMENT=test
#    so the `Authorization: TEST` JWT bypass is honored, and the
#    Postmark stub injected so `comment`/`submit`/`change_status`
#    don't crash on missing API credentials.
docker compose -f docker-compose.yml -f docker-compose.parity.yml \
  up --build -d  # docker-compose.parity.yml is committed alongside

# OR (the form actually used 2026-05-21, since the upstream Dockerfile's
# ENTRYPOINT/CMD interaction means `bundle exec puma` must be passed
# explicitly):
docker run -d --name csp-ruby-parity -p 3000:3000 \
  -e MONGODB_CONNECTION_STRING='mongodb://admin:admin@host.docker.internal:27017' \
  -e MONGODB_DATABASE=parity-ruby \
  -e ENVIRONMENT=test \
  -e RACK_ENV=development \
  -e POSTMARK_API_TOKEN=fake \
  -v /Users/.../csp-api:/home/app \
  --entrypoint bundle csp-api-web \
  exec ruby -r/home/app/elixir/scripts/parity_postmark_stub.rb \
    -S puma -C puma.rb

# 3. Boot Phoenix in test mode (JWT bypass on) against parity-phx.
MIX_ENV=test PHX_SERVE_TEST=1 \
  MONGO_URL_TEST='mongodb://admin:admin@localhost:27017/parity-phx?authSource=admin' \
  mix phx.server &

# 4. Run the diff.
RUBY_BASE=http://localhost:3000 \
  PHX_BASE=http://localhost:4002 \
  CSP_API_KEY=parity-test-key \
  ./scripts/post_parity_diff.sh
```

`scripts/parity_postmark_stub.rb` monkey-patches
`Postmark::ApiClient#deliver_with_template` to a no-op so the
status-change emails the Ruby app sends don't require real Postmark
credentials.
