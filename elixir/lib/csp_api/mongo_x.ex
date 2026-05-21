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
      %{"cursor" => %{"firstBatch" => docs, "id" => cursor_id, "ns" => ns}} ->
        drain([docs], cursor_id, ns)

      _ ->
        []
    end
  end

  # Mongo returns at most ~101 documents in `firstBatch`; the rest stay on the
  # server-side cursor and have to be pulled with `getMore`. The previous
  # implementation ignored the cursor entirely, silently capping every result
  # set at the first batch.
  defp drain(batches, 0, _ns), do: batches |> Enum.reverse() |> Enum.concat()

  defp drain(batches, cursor_id, ns) do
    coll = ns |> String.split(".", parts: 2) |> List.last()

    case Mongo.Ecto.command(Repo,
           getMore: cursor_id,
           collection: coll,
           batchSize: 1000
         ) do
      %{"cursor" => %{"nextBatch" => batch, "id" => next_id}} ->
        drain([batch | batches], next_id, ns)

      _ ->
        batches |> Enum.reverse() |> Enum.concat()
    end
  end

  # find_one delegates to find/3 with `limit: 1` so the cursor-drain path is
  # the same — at most one document arrives in `firstBatch` and `cursor.id`
  # is 0, so `drain/3` returns immediately. Kept as a separate function to
  # match the symmetric Mongo client API the rest of the codebase expects.
  def find_one(coll, filter, opts \\ []) do
    case find(coll, filter, Keyword.put(opts, :limit, 1)) do
      [doc | _] -> doc
      _ -> nil
    end
  end

  @doc """
  Recursively renames Mongo's `"_id"` to `"id"` so the value can be handed
  to a `CspApiWeb.View` (which reads the conventional `:id`/`"id"` key).
  Walks into nested maps and lists of maps. Use at the data-context
  boundary on raw cursor results before passing them to a view.
  """
  def normalize_id(%{} = map) when not is_struct(map) do
    map
    |> Enum.map(fn
      {"_id", v} -> {"id", normalize_id(v)}
      {k, v} -> {k, normalize_id(v)}
    end)
    |> Map.new()
  end

  def normalize_id(list) when is_list(list), do: Enum.map(list, &normalize_id/1)
  def normalize_id(other), do: other

  defp add_opt(list, _key, nil), do: list
  defp add_opt(list, key, value), do: list ++ [{key, value}]
end
