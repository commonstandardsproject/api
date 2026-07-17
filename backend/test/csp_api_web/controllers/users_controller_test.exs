defmodule CspApiWeb.UsersControllerTest do
  use CspApiWeb.ConnCase, async: false

  test "POST /users/signed_in upserts a user with a fresh api key", %{conn: conn} do
    %{"data" => user} =
      conn
      |> post("/api/v1/users/signed_in", %{
        "profile" => %{"email" => "new@example.com", "name" => "Newbie"}
      })
      |> json_response(200)

    assert user["email"] == "new@example.com"
    assert is_binary(user["apiKey"]) and byte_size(user["apiKey"]) > 0
    assert user["id"]
  end

  test "POST /users/signed_in is idempotent for the same email", %{conn: conn} do
    body = %{"profile" => %{"email" => "twice@example.com", "name" => "Twice"}}

    %{"data" => first} = conn |> post("/api/v1/users/signed_in", body) |> json_response(200)
    %{"data" => second} = conn |> post("/api/v1/users/signed_in", body) |> json_response(200)

    assert first["id"] == second["id"]
    assert first["apiKey"] == second["apiKey"]
  end

  test "POST /users/:id/allowed_origins replaces the list", %{conn: conn} do
    %{"data" => created} =
      conn
      |> post("/api/v1/users/signed_in", %{
        "profile" => %{"email" => "origins@example.com", "name" => "Origins"}
      })
      |> json_response(200)

    %{"data" => updated} =
      conn
      |> post("/api/v1/users/#{created["id"]}/allowed_origins", %{
        "data" => ["https://example.org"]
      })
      |> json_response(200)

    assert updated["allowedOrigins"] == ["https://example.org"]
  end
end
