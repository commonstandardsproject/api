defmodule CspApi.Algolia do
  @moduledoc """
  Pushes standard sets to Algolia after they're approved.

  In Ruby, `StandardSet.update` calls `SendToAlgolia.standard_set(set)`,
  which flattens each standard with its ancestor metadata and bulk-adds
  to the `common-standards-project` index. The Elixir port preserves
  that — `StandardSets.upsert/1` calls `CspApi.Algolia.index/1`, which
  dispatches to a configured adapter.

  Adapters live in `CspApi.Algolia.{AlgoliaAdapter, TestAdapter}`. Tests
  use the test adapter to capture payloads in the process dictionary;
  production uses the live `algolia_ex` client.

  The default index name is `common-standards-project`, configurable
  via `config :csp_api, :algolia, index: "..."`.
  """

  alias CspApi.Hierarchy

  @default_index "common-standards-project"

  @doc "Indexes a single standard set. Called from `StandardSets.upsert`."
  def index(%{} = set) do
    payload = denormalize_standards(set)
    adapter().index(index_name(), payload)
  end

  defp adapter do
    Application.get_env(:csp_api, :algolia_adapter, CspApi.Algolia.AlgoliaAdapter)
  end

  defp index_name do
    case Application.get_env(:csp_api, :algolia, []) do
      opts when is_list(opts) -> Keyword.get(opts, :index, @default_index)
      _ -> @default_index
    end
  end

  @doc """
  Flattens a standard set into one Algolia object per standard, mirroring
  `SendToAlgolia.denormalize_standards` in the Ruby app.
  """
  def denormalize_standards(set) do
    standards = get(set, :standards) || %{}
    standards_with_ancestors = Hierarchy.add_ancestor_ids(standards)

    document = get(set, :document) || %{}
    jurisdiction = get(set, :jurisdiction) || %{}

    publication_status = get_in_map(document, ["publicationStatus"])

    set_id = get(set, :id) || get(set, :_id)
    set_title = get(set, :title)
    subject = get(set, :subject)
    normalized_subject = get(set, :normalizedSubject)
    education_levels = get(set, :educationLevels) || []
    juris_id = get_in_map(jurisdiction, ["id"])

    standards_with_ancestors
    |> Map.values()
    |> Enum.map(fn s ->
      ancestor_ids = s["ancestorIds"] || []

      ancestor_descriptions =
        ancestor_ids
        |> Enum.map(fn aid -> standards_with_ancestors[aid] && standards_with_ancestors[aid]["description"] end)
        |> Enum.reject(&is_nil/1)

      s
      |> Map.merge(%{
        "objectID" => s["id"],
        "ancestorIds" => ancestor_ids,
        "ancestorDescriptions" => ancestor_descriptions,
        "educationLevels" => education_levels,
        "subject" => subject,
        "normalizedSubject" => normalized_subject,
        "standardSet" => %{"title" => set_title, "id" => set_id},
        "jurisdiction" =>
          jurisdiction
          |> deep_to_string_keys()
          |> Map.delete("__struct__"),
        "document" => %{"publicationStatus" => publication_status},
        "_tags" =>
          List.flatten([
            ancestor_ids,
            [set_id],
            [juris_id],
            education_levels
          ])
          |> Enum.reject(&is_nil/1)
      })
    end)
  end

  defp get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get_in_map(map, [key]) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp deep_to_string_keys(%_{} = struct), do: struct |> Map.from_struct() |> deep_to_string_keys()

  defp deep_to_string_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), deep_to_string_keys(v)}
      {k, v} -> {k, deep_to_string_keys(v)}
    end)
  end

  defp deep_to_string_keys(other), do: other
end
