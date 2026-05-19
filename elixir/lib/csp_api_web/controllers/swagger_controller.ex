defmodule CspApiWeb.SwaggerController do
  use CspApiWeb, :controller

  # Bare-minimum swagger doc — enough that smoke tests can check for 200.
  # The Ruby app generated this via grape-swagger. A full port is out of
  # scope for the conversion.
  def index(conn, _params) do
    json(conn, %{
      apiVersion: "v1",
      info: %{title: "CSP API"},
      basePath: "/api/v1"
    })
  end
end
