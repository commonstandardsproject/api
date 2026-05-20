import Config

# Tests use a dedicated database that the test helper truncates between
# runs. The database name MUST contain "test" — `CspApi.TestCase` refuses to
# clear anything else.
config :csp_api, CspApi.Repo,
  url: System.get_env("MONGO_URL_TEST") || "mongodb://localhost:27017/csp-test",
  pool_size: 2

# `server: false` so `mix test` doesn't accidentally bind a port. The
# contract test runner opts in with `PHX_SERVE_TEST=1` (read in
# config/runtime.exs) to bring up the endpoint against a (test-only)
# database, so the language-neutral Python contract suite can run against
# the Phoenix port.
config :csp_api, CspApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-only-secret-key-replace-in-prod-_______________________________",
  server: false

# Only enabled in :test. The Ruby rspec suite hits POST endpoints with
# `Authorization: TEST`; the Elixir port honors that under the same gate.
config :csp_api, :auth,
  jwt_test_bypass?: true,
  jwt_secret: nil,
  jwt_client_id: nil

config :logger, level: :warning
