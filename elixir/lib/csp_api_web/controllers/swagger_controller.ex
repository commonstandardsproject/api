defmodule CspApiWeb.SwaggerController do
  @moduledoc """
  Renders the live OpenAPI 3.0 spec, replacing the old grape-swagger
  endpoint at `GET /api/v1/swagger_doc`.

  The spec is built by `CspApiWeb.ApiSpec` from operation
  declarations on each controller and the schemas in
  `CspApiWeb.Schemas`.
  """

  use CspApiWeb, :controller

  def index(conn, _params) do
    # `OpenApiSpex.OpenApi.to_map/1` walks the spec tree and rewrites
    # every internal struct (`Info`, `PathItem`, `Schema`…) into a
    # plain map suitable for Jason. Once we have a plain map we can
    # layer on the legacy grape-swagger top-level keys (`apiVersion`,
    # `basePath`) so consumers still parsing the old shape don't
    # break.
    spec_map = OpenApiSpex.OpenApi.to_map(CspApiWeb.ApiSpec.spec())
    json(conn, Map.merge(spec_map, %{"apiVersion" => "v1", "basePath" => "/api/v1"}))
  end
end
