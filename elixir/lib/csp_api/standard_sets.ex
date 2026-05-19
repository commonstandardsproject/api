defmodule CspApi.StandardSets do
  @moduledoc """
  Read operations on the `standard_sets` collection plus the
  hierarchy-augmentation step that the Ruby app applies before serializing.
  """

  alias CspApi.{Mongo, Hierarchy}

  @doc """
  Fetches a single standard set by id. Returns `nil` if missing. The
  `standards` map is enriched with `parentId`/`ancestorIds` exactly like the
  Ruby endpoint does via `StandardHierarchy.add_ancestor_ids`.
  """
  def get(id) do
    case Mongo.find_one("standard_sets", %{"_id" => id}) do
      nil ->
        nil

      set ->
        standards = Hierarchy.add_ancestor_ids(set["standards"] || %{})

        set
        |> Map.put("standards", standards)
        |> Map.put_new("educationLevels", [])
        |> Map.put("id", set["_id"])
    end
  end

  @doc "Like `get/1` but returns standards as a list (sorted by position desc)."
  def get_with_array(id) do
    case get(id) do
      nil ->
        nil

      set ->
        list =
          set["standards"]
          |> Map.values()
          |> Enum.sort_by(&(&1["position"] || 0), :desc)

        Map.put(set, "standards", list)
    end
  end

  @doc """
  Upserts a standard set. Matches Ruby `StandardSet.update` semantics:
  bumps `version`, sets `updatedAt`, computes `standardsCount`, and stores
  the previous revision in `standard_set_versions`.
  """
  def upsert(%{"id" => id} = doc) when is_binary(id) do
    old = Mongo.find_one("standard_sets", %{"_id" => id}) || %{}
    if map_size(old) > 0, do: save_version(old)

    standards = doc["standards"] || %{}
    version = (old["version"] || 0) + 1

    doc =
      doc
      |> Map.drop(["id", "_id"])
      |> Map.put("version", version)
      |> Map.put("updatedAt", DateTime.utc_now())
      |> Map.put("standardsCount", map_size(standards))

    Mongo.find_one_and_update("standard_sets", %{"_id" => id}, %{"$set" => doc},
      upsert: true,
      return_document: :after
    )
  end

  defp save_version(old) do
    versioned =
      old
      |> Map.put("standardSetId", old["_id"])
      |> Map.put("_id", CspApi.ID.csp_uuid())
      |> Map.put("createdAt", DateTime.utc_now())

    Mongo.insert_one("standard_set_versions", versioned)
  end
end
