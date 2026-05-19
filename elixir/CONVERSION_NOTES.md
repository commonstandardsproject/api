# Conversion notes — Ruby → Elixir

What each Ruby file maps to in the new tree:

| Ruby                                     | Elixir                                              |
| ---------------------------------------- | --------------------------------------------------- |
| `api/api.rb` (mount, before, helpers)    | `lib/csp_api_web/router.ex` + plugs                 |
| `api/api.rb` API-Key auth `before` block | `lib/csp_api_web/plugs/api_key_auth.ex`             |
| `api/api.rb` `validate_token` helper     | `lib/csp_api_web/plugs/jwt_auth.ex`                 |
| `api/jurisdictions.rb`                   | `lib/csp_api_web/controllers/jurisdictions_controller.ex` |
| `api/standard_sets.rb`                   | `lib/csp_api_web/controllers/standard_sets_controller.ex` |
| `api/standard_documents.rb`              | `lib/csp_api_web/controllers/standard_documents_controller.ex` |
| `api/pull_requests.rb`                   | `lib/csp_api_web/controllers/pull_requests_controller.ex` |
| `api/users.rb`                           | `lib/csp_api_web/controllers/users_controller.ex`   |
| `api/entities/*`                         | `lib/csp_api_web/json/*`                            |
| `models/standard_set.rb`                 | `lib/csp_api/standard_sets.ex`                      |
| `models/jurisdiction.rb`                 | `lib/csp_api/jurisdictions.ex`                      |
| `models/pull_request.rb`                 | `lib/csp_api/pull_requests.ex`                      |
| `models/user.rb`                         | `lib/csp_api/users.ex`                              |
| `models/activity.rb`                     | inlined into `lib/csp_api/pull_requests.ex`         |
| `models/email.rb`                        | `lib/csp_api/email.ex` (with pluggable adapter)     |
| `lib/standard_hierarchy.rb`              | `lib/csp_api/hierarchy.ex`                          |
| `lib/securerandom.rb`                    | `lib/csp_api/id.ex`                                 |
| `config/mongo.rb`                        | `lib/csp_api/mongo.ex` + `config/*.exs`             |

## Things that are intentionally different

- **Ecto.** The Ruby app stored everything in MongoDB through the raw
  driver. The Elixir port uses `mongodb_driver` directly (no Ecto schemas).
  An Ecto adapter for Mongo exists (`mongodb_ecto`), but it's awkward for
  documents like a `standard_set` whose `standards` field is a nested map
  keyed by id. Contexts (`CspApi.Jurisdictions`, `CspApi.StandardSets`,
  …) keep the boundary that Ecto would have given us; only the row format
  is different.
- **Auth0 / JWT.** Ruby decoded the token with the URL-decoded client
  secret. The Elixir port does the same via Joken. In `:test` environment
  an `Authorization: TEST` header bypasses verification, exactly like the
  Ruby rspec suite relied on.
- **No-Api-Key bug.** The Ruby `before do` accidentally allows requests
  with a missing `Api-Key` header (MongoDB matches the nil query against
  a system user that has no `apiKey` field). The Elixir port closes that
  hole — a missing or empty key returns 401.
- **Importer.** `importer/` and `lib/cache_standards.rb` /
  `lib/send_to_algolia.rb` are out of scope for the API conversion and
  not ported. The Algolia search index is a separate concern and the
  Phoenix port simply doesn't write to it.

## Things that are intentionally the same

- The wire format. Field names, casing, presence of empty defaults
  (`cspStatus: {}`, `educationLevels: []`), the `standards` map keyed by
  id, the `standardsAsArray=true` query flag, and the
  `hideHiddenSets=true` default all match.
- The `ancestorIds` / `parentId` derivation. The same position-desc walk
  is implemented in `lib/csp_api/hierarchy.ex`. There's a dedicated
  unit test against a trimmed sample of the live Maryland Math Grade 1
  response.
- Status transitions for pull requests, including the quirky
  "silently keep `draft` when status is unknown" behavior the Ruby
  controller has.
- `signed_in` is idempotent on `email` and generates `apiKey` on first
  insert.

## Test layout

- `test/csp_api/hierarchy_test.exs` — pure unit test (no Mongo).
- `test/csp_api_web/controllers/*_test.exs` — in-process Phoenix tests.
  They run the actual router/plug stack and read/write a local MongoDB
  via `Mongo.delete_many(:mongo, …, %{})` between cases.
- `../contract_tests/` — Python HTTP contract suite, runnable against
  either the live Ruby app or `mix phx.server`.
