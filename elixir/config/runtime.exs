import Config

if config_env() == :prod do
  mongo_url =
    System.get_env("MONGO_URL") ||
      raise """
      MONGO_URL environment variable is missing.
      """

  config :csp_api, :mongo,
    name: :mongo,
    url: mongo_url,
    pool_size: String.to_integer(System.get_env("MONGO_POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing"

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :csp_api, CspApiWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "localhost", port: 80],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  config :csp_api, :auth,
    jwt_secret: System.get_env("AUTH0_CLIENT_SECRET"),
    jwt_client_id: System.get_env("AUTH0_CLIENT_ID")
end
