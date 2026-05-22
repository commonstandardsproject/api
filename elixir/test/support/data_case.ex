defmodule CspApi.DataCase do
  @moduledoc """
  Base case for tests that hit the Repo.

  mongodb_ecto doesn't have an SQL-style sandbox (Mongo's transaction
  story differs from Postgres), so we use the simplest correct approach:
  truncate every collection between tests. Tests stay sync (`async:
  false`) since they share one database.

  A safety belt checks the configured database name against a regex
  before truncating — exactly the pattern the Ruby spec uses.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Tests in this case talk to MongoDB. When the test runner can't reach
      # Mongo (e.g. CI without a Mongo service) test_helper.exs configures
      # ExUnit to exclude :mongo so these get skipped.
      @moduletag :mongo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias CspApi.Repo
      alias CspApi.Schemas

      import CspApi.DataCase
    end
  end

    setup _tags do
    :ok = CspApi.DataCase.reset_repo!()
    Process.put(:sent_emails, [])
    :ok
  end

  @collections ~w(
    users
    jurisdictions
    standard_sets
    standard_set_versions
    pull_requests
    standard_documents
    cached_standards
  )

  @doc """
  Truncates every collection. Refuses to run if the database name doesn't
  match the "test" guard.
  """
  def reset_repo! do
    assert_test_database!()

    Enum.each(@collections, fn coll ->
      _ = Mongo.Ecto.command(CspApi.Repo, delete: coll, deletes: [%{q: %{}, limit: 0}])
    end)

    :ok
  end

  defp assert_test_database! do
    url = Application.get_env(:csp_api, CspApi.Repo)[:mongo_url]

    unless is_binary(url) and String.contains?(url, "test") do
      raise """
      Refusing to truncate collections — Repo URL #{inspect(url)} doesn't
      look like a test database. Set MONGO_URL_TEST or update
      config/test.exs.
      """
    end
  end
end
