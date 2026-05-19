import Config

config :csp_api, CspApiWeb.Endpoint, server: true

config :csp_api, :auth, jwt_test_bypass?: false

config :logger, level: :info
