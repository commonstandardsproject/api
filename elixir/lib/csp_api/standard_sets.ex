defmodule CspApi.StandardSets do
  @moduledoc """
  Read + upsert operations on `standard_sets`. Includes the hierarchy
  walk that mirrors `lib/standard_hierarchy.rb`.
  """

  import Ecto.Query
  alias CspApi.{Repo, Hierarchy, ID}
  alias CspApi.Schemas.StandardSet

  @doc """
  Fetches a standard set, augments `standards` with `parentId`/`ancestorIds`,
  and returns the changeset-loaded struct or `nil`.
  """
  def get(id) do
    case Repo.get(StandardSet, id) do
      nil ->
        nil

      set ->
        Map.put(set, :standards, Hierarchy.add_ancestor_ids(set.standards || %{}))
    end
  end

  @doc "Same as `get/1` but returns the standards collection as a position-desc list."
  def get_with_array(id) do
    case get(id) do
      nil ->
        nil

      set ->
        list =
          set.standards
          |> Map.values()
          |> Enum.sort_by(&(&1["position"] || 0), :desc)

        Map.put(set, :standards, list)
    end
  end

  @doc """
  Upserts a standard set, bumping `version`, recomputing `standardsCount`,
  and stashing the previous revision in `standard_set_versions`.

  Atomic on `version`: the entire write is a single `findAndModify` with
  `$inc` on `version` and `$set` on everything else. Mongo serializes
  concurrent calls against the same `_id`, so two simultaneous upserts
  can't both produce `version=N+1` — they're guaranteed to land at N+1
  and N+2 in some order.

  Returns `{:ok, struct}` or `{:error, changeset}`.
  """
  def upsert(attrs) when is_map(attrs) do
    # Stringify atom keys (GC-safe — unlike the reverse, which the old
    # `atomize_keys` did and exposed an atom-table DoS through user input).
    # `Ecto.Changeset.cast` rejects mixed-key maps, so we have to commit
    # to one key style; string keys match the wire shape from Mongo / JSON.
    attrs = stringify_keys(attrs)
    id = attrs["id"] || attrs["_id"]

    if is_nil(id) do
      {:error, "id is required for upsert"}
    else
      # Run the changeset against an empty struct so all validations
      # (`validate_required`, `validate_education_levels`, embed casts) fire
      # regardless of whether the doc already exists in Mongo.
      changeset = StandardSet.changeset(%StandardSet{id: id}, Map.put(attrs, "id", id))

      if changeset.valid? do
        do_atomic_upsert(Ecto.Changeset.apply_changes(changeset))
      else
        {:error, changeset}
      end
    end
  end

  defp stringify_keys(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      kv -> kv
    end)
  end

  defp do_atomic_upsert(%StandardSet{} = applied) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    standards = applied.standards || %{}

    # Build the `$set` payload from the validated struct. Drop the primary
    # key (it's in the query), `version` (handled by `$inc`), and
    # `createdAt` (only set on first insert via `$setOnInsert`). The
    # adapter encodes the rest, including the embedded Ecto sub-docs,
    # once we flatten them to plain maps.
    set_payload =
      applied
      |> deep_demap_struct()
      |> Map.drop([:_id, :id, :version, :createdAt])
      |> Map.put(:updatedAt, now)
      |> Map.put(:standardsCount, map_size(standards))

    result =
      Mongo.Ecto.command(Repo,
        findAndModify: "standard_sets",
        query: %{"_id" => applied.id},
        update: %{
          "$inc" => %{"version" => 1},
          "$set" => set_payload,
          "$setOnInsert" => %{"createdAt" => now}
        },
        upsert: true,
        new: false
      )

    # `new: false` returns the PRE-update doc. On insert it's nil. On
    # update we stash it in `standard_set_versions` — Mongo serializes
    # the findAndModify, so the returned `value` is the immediately-prior
    # revision even under concurrent calls.
    case result do
      %{"value" => nil} -> :ok
      %{"value" => old} when is_map(old) -> save_version(old)
      _ -> :ok
    end

    case Repo.get(StandardSet, applied.id) do
      nil ->
        {:error, "post-upsert read returned nil"}

      %StandardSet{} = set ->
        CspApi.CachedStandards.one(set)
        CspApi.Algolia.index(set)
        {:ok, set}
    end
  end

  # Accepts either an Ecto-loaded `%StandardSet{}` (atom keys, `:id`) or a
  # raw Mongo doc (string keys, `"_id"`). The new atomic upsert path hands
  # us the latter via `findAndModify(new: false)`.
  defp save_version(%StandardSet{} = old), do: save_version(deep_demap_struct(old))

  defp save_version(%{} = old) do
    old_id = old[:id] || old[:_id] || old["_id"] || old["id"]

    versioned =
      old
      |> Map.drop([:__meta__, :_id, "_id", :id])
      |> Map.put("standardSetId", old_id)
      |> Map.put("_id", ID.csp_uuid())
      |> Map.put("createdAt", DateTime.utc_now() |> DateTime.truncate(:second))

    Mongo.Ecto.command(Repo, insert: "standard_set_versions", documents: [versioned])
  end

  # `Map.from_struct/1` is shallow — nested embeds_one values stay as
  # structs and the BSON encoder rejects them. Recursively turn every
  # `%Schema{}` into a plain map (keeping DateTime + BSON-shaped structs
  # intact so the encoder can handle them).
  defp deep_demap_struct(%mod{} = struct)
       when mod not in [DateTime, NaiveDateTime, Date, Time, BSON.UTCDateTime, BSON.ObjectId] do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Map.new(fn {k, v} -> {k, deep_demap_struct(v)} end)
  end

  defp deep_demap_struct(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn {k, v} -> {k, deep_demap_struct(v)} end)
  end

  defp deep_demap_struct(list) when is_list(list), do: Enum.map(list, &deep_demap_struct/1)
  defp deep_demap_struct(other), do: other

  @doc false
  def query_by_jurisdiction(jurisdiction_id) do
    # Used only by tests; mongodb_ecto needs `fragment` for nested-field
    # filters (Ecto's standard DSL doesn't allow embed navigation).
    from s in StandardSet, where: fragment("jurisdiction.id": ^jurisdiction_id)
  end
end
