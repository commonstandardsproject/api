import Config

config :csp_api,
  ecto_repos: [CspApi.Repo]

config :csp_api, CspApi.Repo,
  adapter: Mongo.Ecto,
  mongo_url: System.get_env("MONGO_URL") || "mongodb://localhost:27017/csp",
  pool_size: 5

config :csp_api, CspApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: CspApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CspApi.PubSub

config :phoenix, :json_library, Jason

config :csp_api, :auth,
  jwt_secret: System.get_env("AUTH0_CLIENT_SECRET"),
  jwt_client_id: System.get_env("AUTH0_CLIENT_ID"),
  # Compile-time-only — never enable outside test config. The
  # CspApiWeb.Plugs.JwtAuth plug rejects requests with `Authorization: TEST`
  # unless this flag is true.
  jwt_test_bypass?: false

import_config "#{config_env()}.exs"
