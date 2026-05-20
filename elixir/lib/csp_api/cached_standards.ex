defmodule CspApi.CachedStandards do
  @moduledoc """
  Denormalized per-standard cache. Port of `lib/cache_standards.rb`.

  Every time a `standard_sets` document is upserted, every standard in
  the set is written (or replaced) as a row in `cached_standards`,
  keyed by standard id, with the parent set's metadata flattened in.
  Downstream consumers read `cached_standards` to avoid loading the
  whole parent set just to look up a single standard.
  """

  alias CspApi.{Repo, Hierarchy}

  @doc """
  Rebuilds `cached_standards` rows for one standard set. Mirrors
  `CachedStandards.one/1` from the Ruby app.
  """
  def one(%{standards: standards} = set) when is_map(standards) and map_size(standards) > 0 do
    write_rows(set, standards)
  end

  def one(%{"standards" => standards} = set) when is_map(standards) and map_size(standards) > 0 do
    write_rows(set, standards)
  end

  def one(_), do: :ok

  defp write_rows(set, standards) do
    walked = Hierarchy.add_ancestor_ids(standards)

    set_id =
      get(set, :id) || get(set, :_id)

    document = get(set, :document) || %{}
    jurisdiction = get(set, :jurisdiction) || %{}

    common = %{
      "standardSetId" => set_id,
      "standardSetTitle" => get(set, :title),
      "standardDocumentId" => Map.get(document, :id) || Map.get(document, "id"),
      "jurisdictionId" => Map.get(jurisdiction, :id) || Map.get(jurisdiction, "id"),
      "jurisdictionTitle" => Map.get(jurisdiction, :title) || Map.get(jurisdiction, "title"),
      "subject" => get(set, :subject),
      "educationLevels" => get(set, :educationLevels) || [],
      "createdAt" => get(set, :createdAt),
      "updatedAt" => get(set, :updatedAt)
    }

    walked
    |> Map.values()
    |> Enum.each(fn s ->
      doc =
        common
        |> Map.merge(%{
          "_id" => s["id"],
          "asnIdentifier" => s["asnIdentifier"],
          "position" => s["position"],
          "depth" => s["depth"],
          "statementNotation" => s["statementNotation"],
          "altStatementNotation" => s["altStatementNotation"],
          "statementLabel" => s["statementLabel"],
          "listId" => s["listId"],
          "description" => s["description"],
          "comments" => s["comments"],
          "ancestorIds" => s["ancestorIds"] || []
        })

      # Upsert each row. Ruby uses `bulk_write` with `replace_one + upsert`;
      # we do the equivalent through the adapter.
      Mongo.Ecto.command(Repo,
        update: "cached_standards",
        updates: [
          %{
            "q" => %{"_id" => s["id"]},
            "u" => doc,
            "upsert" => true
          }
        ]
      )
    end)

    :ok
  end

  # Convenience for either a struct (atom keys) or a raw map (string keys).
  defp get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
