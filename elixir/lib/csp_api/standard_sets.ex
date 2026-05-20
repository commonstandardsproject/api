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

  Returns `{:ok, struct}` or `{:error, changeset}`.
  """
  def upsert(attrs) when is_map(attrs) do
    # Normalize to atom keys so subsequent Map.put's don't produce a
    # mixed atom/string keyset (Ecto.Changeset.cast rejects mixed maps).
    attrs = atomize_keys(attrs)

    id = attrs[:id] || attrs[:_id]

    if is_nil(id) do
      {:error, "id is required for upsert"}
    else
      old = Repo.get(StandardSet, id)

      if old, do: save_version(old)

      standards = attrs[:standards] || %{}

      attrs =
        attrs
        |> Map.put(:id, id)
        |> Map.put(:version, (old && old.version || 0) + 1)
        |> Map.put(:updatedAt, DateTime.utc_now() |> DateTime.truncate(:second))
        |> Map.put(:standardsCount, map_size(standards))

      changeset = StandardSet.changeset(old || %StandardSet{}, attrs)

      case Repo.insert_or_update(changeset) do
        {:ok, set} = ok ->
          # Mirror Ruby's `StandardSet.update`:
          #   * rebuild the denormalized `cached_standards` rows
          #   * push the new revision into Algolia
          CspApi.CachedStandards.one(set)
          CspApi.Algolia.index(set)
          ok

        other ->
          other
      end
    end
  end

  # Top-level only — embedded sub-doc maps (jurisdiction, document, etc.)
  # keep whatever key style they came in with, since the StandardSet
  # changeset's stringify-on-cast already normalizes them.
  defp atomize_keys(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      kv -> kv
    end)
  end

  defp save_version(old) do
    versioned =
      old
      |> deep_demap_struct()
      |> Map.put(:standardSetId, old.id)
      |> Map.put(:id, ID.csp_uuid())
      |> Map.put(:createdAt, DateTime.utc_now() |> DateTime.truncate(:second))

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
    # Used only by tests that already insert via raw mongo; not part of
    # the public API.
    from(s in StandardSet) |> where_jurisdiction(jurisdiction_id)
  end

  defp where_jurisdiction(query, jurisdiction_id) do
    from s in query, where: fragment("?", field(s, :jurisdiction)) == ^%{"id" => jurisdiction_id}
  end
end
