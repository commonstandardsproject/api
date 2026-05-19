defmodule CspApiWeb.ConnCase do
  @moduledoc """
  Base case for controller tests. Builds on `CspApi.DataCase`, adds a
  configured `Plug.Conn` and seeds a test user we can authenticate as.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use CspApi.DataCase
      import Plug.Conn
      import Phoenix.ConnTest
      import CspApiWeb.ConnCase

      @endpoint CspApiWeb.Endpoint
    end
  end

  setup _tags do
    :ok = CspApi.DataCase.reset_repo!()
    Process.put(:sent_emails, [])

    user =
      CspApi.Users.create(%{
        id: "tester",
        email: "test@test.com",
        apiKey: "testing",
        profile: %{"name" => "Tester"},
        isCommitter: true
      })

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/json")
      |> with_api_key("testing")
      |> with_test_jwt()

    {:ok, conn: conn, user: user}
  end

  def with_api_key(conn, key), do: Plug.Conn.put_req_header(conn, "api-key", key)
  def with_test_jwt(conn), do: Plug.Conn.put_req_header(conn, "authorization", "TEST")
end
