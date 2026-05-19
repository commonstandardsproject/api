defmodule CspApiWeb.AuthTest do
  use CspApiWeb.ConnCase, async: false

  test "valid api key returns 200", %{conn: conn} do
    conn = get(conn, "/api/v1/jurisdictions")
    assert conn.status == 200
    assert %{"data" => list} = json_response(conn, 200)
    assert is_list(list)
  end

  test "invalid api key returns 401", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_req_header("api-key", "not-a-real-key")
      |> get("/api/v1/jurisdictions")

    assert conn.status == 401
    assert %{"error" => "Unauthorized" <> _} = json_response(conn, 401)
  end

  test "swagger doc is public", %{conn: conn} do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> get("/api/v1/swagger_doc")

    assert conn.status == 200
  end
end
