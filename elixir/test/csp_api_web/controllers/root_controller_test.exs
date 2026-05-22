defmodule CspApiWeb.RootControllerTest do
  use CspApiWeb.ConnCase, async: false

  @moduletag :mongo

  test "GET / serves the Swagger UI viewer pointed at /api/v1/swagger_doc" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/")

    assert conn.status == 200

    [content_type] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "text/html"

    body = response(conn, 200)
    assert body =~ ~s(<title>Common Standards Project API</title>)
    assert body =~ ~s(url: "/api/v1/swagger_doc")
    assert body =~ "swagger-ui-bundle.js"
  end

  test "GET / does not require an API key (matches Ruby Main Sinatra route)" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.delete_req_header("api-key")
      |> get("/")

    assert conn.status == 200
  end
end
