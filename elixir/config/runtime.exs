import Config

# Atlas (`mongodb+srv://`) auto-enables TLS in mongodb_driver. On OTP 26+,
# :ssl.connect/3 defaults verify to :verify_peer and refuses to start without
# explicit cacerts, so we have to inject them. :public_key.cacerts_get/0
# (OTP 25+) pulls the platform trust store. Applies to any env that points
# MONGO_URL at an SRV string; non-TLS URLs ignore the option.
if System.get_env("MONGO_READ_ONLY") in ["1", "true"] do
  if config_env() == :prod do
    raise """
    MONGO_READ_ONLY=1 is set with MIX_ENV=prod. This flag is for parity
    diffs against a read-only replica — it disables the `findAndModify`
    bump on auth and degrades request-count accounting. Refusing to boot.
    """
  end

  config :csp_api, :mongo_read_only, true
end

if (System.get_env("MONGO_URL") || "") |> String.contains?("+srv") do
  # OTP's default hostname check doesn't honor wildcard SAN entries the way HTTPS
  # clients do, which breaks against Atlas certs (e.g. `*.w80cp.mongodb.net`
  # against `production-shard-00-00.w80cp.mongodb.net`). The `:https` match_fun
  # implements RFC 6125 wildcard matching.
  config :csp_api, CspApi.Repo,
    ssl_opts: [
      cacerts: :public_key.cacerts_get(),
      verify: :verify_peer,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
end

if config_env() == :test do
  # PHX_SERVE_TEST=1 brings the test-mode endpoint up so the language-neutral
  # Python contract suite can run against the Phoenix port with JWT-bypass on.
  if System.get_env("PHX_SERVE_TEST") in ["1", "true"] do
    config :csp_api, CspApiWeb.Endpoint, server: true
  end
end

if config_env() == :prod do
  mongo_url =
    System.get_env("MONGO_URL") ||
      raise "MONGO_URL environment variable is missing."

  config :csp_api, CspApi.Repo,
    mongo_url: mongo_url,
    pool_size: String.to_integer(System.get_env("MONGO_POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing"

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :csp_api, CspApiWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "localhost", port: 80],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true

  config :csp_api, :auth,
    jwt_secret:
      System.get_env("AUTH0_CLIENT_SECRET") ||
        raise("AUTH0_CLIENT_SECRET environment variable is missing"),
    jwt_client_id:
      System.get_env("AUTH0_CLIENT_ID") ||
        raise("AUTH0_CLIENT_ID environment variable is missing"),
    jwt_test_bypass?: false

  # Algolia — production indexing wraps the live `algolia_ex` client.
  config :csp_api,
    algolia_adapter: CspApi.Algolia.AlgoliaAdapter,
    algolia: [index: System.get_env("ALGOLIA_INDEX") || "common-standards-project"]

  config :algolia,
    application_id:
      System.get_env("ALGOLIA_APPLICATION_ID") ||
        raise("ALGOLIA_APPLICATION_ID environment variable is missing"),
    api_key:
      System.get_env("ALGOLIA_API_KEY") ||
        raise("ALGOLIA_API_KEY environment variable is missing")

  # Postmark — emails on PR status change.
  config :csp_api,
    email_adapter: CspApi.Email.PostmarkAdapter,
    postmark_token:
      System.get_env("POSTMARK_API_TOKEN") ||
        raise("POSTMARK_API_TOKEN environment variable is missing"),
    postmark_from:
      System.get_env("POSTMARK_FROM_ADDRESS") ||
        raise("POSTMARK_FROM_ADDRESS environment variable is missing")
end
