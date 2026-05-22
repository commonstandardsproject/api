defmodule CspApiWeb.ApiSpec do
  @moduledoc """
  Top-level OpenAPI 3.0 spec, built by `open_api_spex`.

  Paths are discovered from the Phoenix router — every action that
  declares `operation/2` (via `use OpenApiSpex.ControllerSpecs`)
  contributes a `PathItem`. Schemas are pulled from
  `CspApiWeb.Schemas`.
  """

  alias OpenApiSpex.{Components, Info, OpenApi, Paths, SecurityScheme, Server}
  alias CspApiWeb.{Endpoint, Router}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [Server.from_endpoint(Endpoint)],
      info: %Info{
        title: "Common Standards Project API",
        version: "v1",
        description:
          "Read-only and editorial endpoints for U.S. educational standards. " <>
            "Authoritative spec rendered from the running Phoenix app — " <>
            "see https://commonstandardsproject.com for end-user docs."
      },
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "ApiKeyAuth" => %SecurityScheme{
            type: "apiKey",
            in: "header",
            name: "Api-Key"
          },
          "JwtAuth" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT"
          }
        }
      },
      security: [%{"ApiKeyAuth" => []}]
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
