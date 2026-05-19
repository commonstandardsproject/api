defmodule CspApi.MongoX do
  @moduledoc """
  Escape hatch for queries that don't translate cleanly through Ecto's
  query DSL — namely filters on nested embedded fields like
  `jurisdiction.id` or `cspStatus.value`. We dispatch the raw `find`
  command through the adapter, reusing the repo's existing connection.

  Used sparingly. Top-level CRUD goes through `Repo` and changesets.
  """

  alias CspApi.Repo

  def find(coll, filter, opts \\ []) do
    cmd =
      [find: coll, filter: filter]
      |> add_opt(:projection, opts[:projection])
      |> add_opt(:sort, opts[:sort])
      |> add_opt(:limit, opts[:limit])

    case Mongo.Ecto.command(Repo, cmd) do
      {:ok, %{"cursor" => %{"firstBatch" => docs}}} -> docs
      {:ok, %{cursor: %{firstBatch: docs}}} -> docs
      {:ok, _} -> []
      {:error, _} -> []
    end
  end

  defp add_opt(list, _key, nil), do: list
  defp add_opt(list, key, value), do: list ++ [{key, value}]
end
