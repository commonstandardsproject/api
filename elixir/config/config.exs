import Config

config :csp_api,
  generators: [timestamp_type: :utc_datetime]

config :csp_api, CspApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: CspApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CspApi.PubSub

config :phoenix, :json_library, Jason

config :csp_api, :mongo,
  name: :mongo,
  url: System.get_env("MONGO_URL") || "mongodb://localhost:27017/csp",
  pool_size: 5

config :csp_api, :auth,
  jwt_secret: System.get_env("AUTH0_CLIENT_SECRET"),
  jwt_client_id: System.get_env("AUTH0_CLIENT_ID")

import_config "#{config_env()}.exs"
