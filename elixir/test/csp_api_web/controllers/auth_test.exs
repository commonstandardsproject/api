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

  test "missing api key matches Ruby bug — passes when a system user exists with no apiKey field", %{conn: _conn} do
    # Insert a user with NO apiKey field. The Ruby app's `before` block
    # accidentally matches such users when the header is missing, because
    # `find({apiKey: nil})` in MongoDB matches documents where the field
    # doesn't exist. We replicate that behavior exactly.
    %{"ok" => 1.0} =
      Mongo.Ecto.command(Repo,
        insert: "users",
        documents: [%{_id: "system-no-key", email: "system@example.com", profile: %{name: "System"}}]
      )

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> Plug.Conn.delete_req_header("api-key")
      |> get("/api/v1/jurisdictions")

    assert conn.status == 200
  end

  test "swagger doc is public", %{conn: _conn} do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> get("/api/v1/swagger_doc")

    assert conn.status == 200
  end
end
