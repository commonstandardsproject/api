defmodule CspApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :csp_api

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Gzip responses for clients that send `Accept-Encoding: gzip`.
  # Mirrors `use Rack::Deflater` from config.ru.
  plug CspApiWeb.Plugs.Gzip

  # Matches the Ruby `Rack::Cors do allow do origins '*'; resource '*',
  # headers: :any, methods: [:post, :get, :options] end end`. Sends CORS
  # headers on every request and answers preflight `OPTIONS` directly.
  plug Corsica,
    origins: "*",
    allow_headers: :all,
    allow_methods: ["GET", "POST", "OPTIONS"]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug CspApiWeb.Router
end
