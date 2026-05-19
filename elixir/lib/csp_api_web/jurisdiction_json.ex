defmodule CspApiWeb.JurisdictionJSON do
  @moduledoc "Port of `api/entities/jurisdiction.rb` and `jurisdiction_summary.rb`."

  alias CspApi.Schemas.Jurisdiction
  alias CspApiWeb.StandardSetJSON

  @doc "Shape for `GET /api/v1/jurisdictions`."
  def summary(%Jurisdiction{} = j) do
    %{"id" => j.id, "title" => j.title, "type" => j.type}
  end

  def summary(j) when is_map(j) do
    %{"id" => j["_id"] || j["id"], "title" => j["title"], "type" => j["type"]}
  end

  @doc "Shape for `GET /api/v1/jurisdictions/:id`."
  def full(%Jurisdiction{} = j, standard_sets) do
    %{
      "id" => j.id,
      "title" => j.title,
      "type" => j.type,
      "standardSets" => Enum.map(standard_sets || [], &StandardSetJSON.summary/1)
    }
  end
end
