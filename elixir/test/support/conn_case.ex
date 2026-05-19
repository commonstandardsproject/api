defmodule CspApiWeb.ConnCase do
  @moduledoc """
  Shared setup for controller tests.

  - Drops the test database before each test so collections start empty.
  - Builds a `Plug.Conn` with `accept: application/json`.
  - Provides helpers for signing requests with an API key and the
    `Authorization: TEST` JWT bypass.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import CspApiWeb.ConnCase

      alias CspApiWeb.Router.Helpers, as: Routes

      @endpoint CspApiWeb.Endpoint
    end
  end

  setup _tags do
    CspApiWeb.ConnCase.clear_db!()
    Process.put(:sent_emails, [])

    user = CspApi.Users.create(%{
      "id" => "tester",
      "email" => "test@test.com",
      "apiKey" => "testing",
      "profile" => %{"name" => "Tester"},
      "isCommitter" => true
    })

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> with_api_key("testing")
      |> with_test_jwt()

    {:ok, conn: conn, user: user}
  end

  @doc "Sign the conn with an API key."
  def with_api_key(conn, key) do
    Plug.Conn.put_req_header(conn, "api-key", key)
  end

  @doc "Use the dev-only `Authorization: TEST` bypass for the JWT plug."
  def with_test_jwt(conn) do
    Plug.Conn.put_req_header(conn, "authorization", "TEST")
  end

  @doc "Drop all collections used by the tests."
  def clear_db! do
    Enum.each(
      ~w(users pull_requests jurisdictions standard_sets standard_set_versions standard_documents),
      fn coll ->
        # Best-effort; the collection may not exist yet.
        try do
          Mongo.delete_many(:mongo, coll, %{})
        rescue
          _ -> :ok
        end
      end
    )
  end
end
