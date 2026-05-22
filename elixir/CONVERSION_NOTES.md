# Conversion notes — Ruby → Elixir/Phoenix/Ecto

| Ruby                                     | Elixir                                              |
| ---------------------------------------- | --------------------------------------------------- |
| `api/api.rb` (mount, before, helpers)    | `lib/csp_api_web/router.ex` + plugs                 |
| `api/api.rb` API-Key auth `before` block | `lib/csp_api_web/plugs/api_key_auth.ex`             |
| `api/api.rb` `validate_token` helper     | `lib/csp_api_web/plugs/jwt_auth.ex`                 |
| `api/jurisdictions.rb` (Grape resource)  | `lib/csp_api_web/controllers/jurisdictions_controller.ex` |
| `api/standard_sets.rb`                   | `lib/csp_api_web/controllers/standard_sets_controller.ex` |
| `api/standard_documents.rb`              | `lib/csp_api_web/controllers/standard_documents_controller.ex` |
| `api/pull_requests.rb`                   | `lib/csp_api_web/controllers/pull_requests_controller.ex` |
| `api/users.rb`                           | `lib/csp_api_web/controllers/users_controller.ex`   |
| `api/entities/*`                         | `lib/csp_api_web/json.ex` (one module)              |
| `models/standard_set.rb` (Virtus)        | `lib/csp_api/schemas/standard_set.ex` (Ecto.Schema) |
| `models/jurisdiction.rb`                 | `lib/csp_api/schemas/jurisdiction.ex`               |
| `models/pull_request.rb`                 | `lib/csp_api/schemas/pull_request.ex`               |
| `models/user.rb`                         | `lib/csp_api/schemas/user.ex`                       |
| `models/activity.rb`                     | `lib/csp_api/schemas/activity.ex` (embedded)        |
| `models/email.rb`                        | `lib/csp_api/email.ex` (pluggable adapter)          |
| `lib/standard_hierarchy.rb`              | `lib/csp_api/hierarchy.ex`                          |
| `lib/securerandom.rb`                    | `lib/csp_api/id.ex`                                 |
| `config/mongo.rb`                        | `config/*.exs` + `lib/csp_api/repo.ex`              |

## Stack choices

- **Ecto + mongodb_ecto.** The data store stays MongoDB; the adapter
  gives us `Ecto.Schema`, `Ecto.Changeset`, and `Repo.{get,all,insert,update}`.
  Validation that lived in `dry-validation` `Validator` classes is now
  in changeset functions. For two queries that hit nested embedded fields
  (`jurisdiction.id`, `cspStatus.value`), `CspApi.MongoX` issues a raw
  `find` command through `Mongo.Ecto.command/2` — that's still inside the
  adapter, just bypassing the Ecto query DSL where it can't express the
  filter.

- **`findAndModify` for atomic upserts.** Ruby uses `find_one_and_update`
  with `$inc/$set/$setOnInsert` so an Auth0 sign-in is a single round
  trip. The Elixir port does the same via `Mongo.Ecto.command/2` rather
  than `Repo.update`, because `Repo.update` would require a separate
  fetch and lose the atomicity.

- **Standards as `:map`, not `embeds_many`.** The Ruby model is
  `Hash[String => Standard]`, and Mongo stores it that way. Ecto's
  `embeds_many` would serialize as a list, which would change the wire
  format. We declare `field :standards, :map, default: %{}` so the
  storage shape is preserved exactly.

## Bug-for-bug fidelity to the Ruby app

The Elixir port intentionally preserves these Ruby quirks:

- **Missing `Api-Key` header.** `find({apiKey: nil})` in MongoDB matches
  documents with no `apiKey` field. If a user document like that exists,
  unkeyed requests get authenticated as that user. The Elixir port hits
  Mongo the same way; the controller test `auth_test.exs` pins this
  behavior down.

- **Unknown `change_status` value.** Ruby's `PullRequest.change_status`
  returns `false` for any value outside the known statuses, and the
  controller silently re-fetches and returns the unchanged PR with 200.
  The Elixir `change_status/4` returns `{:error, :invalid_status}` and
  the controller turns that into the same 200.

- **`ancestorIds` walks position-desc forward.** A leaf standard at the
  end of the descending-position list ends up with `ancestorIds: []` if
  there are no entries after it to walk through. `hierarchy.ex` keeps
  that algorithm verbatim and the test asserts it.

- **`standardSet.id` on approval.** When a PR is approved, the embedded
  `standardSet` is written back using whatever `id` is on it — no check
  that it matches `forkedFromStandardSetId`. Same as Ruby.

## Out of scope

- `importer/`, `lib/cache_standards.rb`, `lib/send_to_algolia.rb`.
- The grape-swagger generated docs. `SwaggerController` returns a stub.

## Things flagged but kept the same on purpose

- The Ruby `before` hook also checks `HTTP_ORIGIN` against the user's
  `allowedOrigins`. The Elixir port doesn't yet implement that check; it
  should be added back as a separate plug when production needs it.

- `Email.send_email` doesn't actually hit Postmark — the production
  adapter logs the would-be payload. Wire up the Postmark adapter when
  the env vars are available.
