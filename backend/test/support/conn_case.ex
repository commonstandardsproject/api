defmodule CspApiWeb.ConnCase do
  @moduledoc """
  Base case for controller tests. Does its own Repo reset + user
  seeding; doesn't `use CspApi.DataCase` because chaining the two
  CaseTemplates puts DataCase's reset hook AFTER our user-creation,
  which wipes the user before the test body runs.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Talk to MongoDB — same tag DataCase uses, so the helper-level
      # `:mongo` exclude in test_helper.exs picks these up when Mongo
      # isn't reachable.
      @moduletag :mongo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Plug.Conn
      import Phoenix.ConnTest
      import CspApiWeb.ConnCase

      alias CspApi.Repo
      alias CspApi.Schemas

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
