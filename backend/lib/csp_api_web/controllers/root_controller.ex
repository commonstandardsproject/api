defmodule CspApiWeb.RootController do
  @moduledoc """
  Serves the Swagger UI viewer at `GET /` — the Ruby app's
  `Main < Sinatra::Base` renders `public/index.html` (Swagger UI 2.x with
  jQuery + backbone, only supports Swagger 2.0). The Phoenix port emits
  an OpenAPI 3.0 spec via `open_api_spex`, so we serve Swagger UI 5.x
  from a CDN instead. Same UX, one HTML file, no bundled assets.

  Public — no API key needed to view the docs.
  """
  use CspApiWeb, :controller

  @swagger_ui_version "5.17.14"

  @doc false
  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, page())
  end

  defp page do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Common Standards Project API</title>
      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui.css" />
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui-bundle.js" crossorigin></script>
      <script src="https://unpkg.com/swagger-ui-dist@#{@swagger_ui_version}/swagger-ui-standalone-preset.js" crossorigin></script>
      <script>
        window.onload = function () {
          window.ui = SwaggerUIBundle({
            url: "/api/v1/swagger_doc",
            dom_id: "#swagger-ui",
            deepLinking: true,
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIStandalonePreset
            ],
            layout: "StandaloneLayout"
          });
        };
      </script>
    </body>
    </html>
    """
  end
end
