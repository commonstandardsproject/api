import Config

config :csp_api, CspApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-only-secret-key-replace-in-prod-________________________________"

config :csp_api, :environment, :development

config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
