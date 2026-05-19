import Config

config :csp_api, CspApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-only-secret-key-replace-in-prod-_______________________________",
  server: false

# Tests connect to a local Mongo so they don't touch production. CI / local
# overrides via MONGO_URL_TEST.
config :csp_api, :mongo,
  name: :mongo,
  url: System.get_env("MONGO_URL_TEST") || "mongodb://localhost:27017/csp-test",
  pool_size: 2

config :csp_api, :environment, :test

config :logger, level: :warning
