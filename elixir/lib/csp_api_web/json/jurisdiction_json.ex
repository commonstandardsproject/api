defmodule CspApiWeb.JurisdictionJSON do
  @moduledoc """
  Mirrors `api/entities/jurisdiction.rb` and
  `api/entities/jurisdiction_summary.rb` from the Ruby app.
  """

  alias CspApiWeb.StandardSetJSON

  @doc "Shape for `GET /api/v1/jurisdictions`."
  def summary(j) do
    %{
      "id" => j["_id"] || j["id"],
      "title" => j["title"],
      "type" => j["type"]
    }
  end

  @doc "Shape for `GET /api/v1/jurisdictions/:id` — adds nested `standardSets`."
  def full(j) do
    %{
      "id" => j["_id"] || j["id"],
      "title" => j["title"],
      "type" => j["type"],
      "standardSets" => Enum.map(j["standardSets"] || [], &StandardSetJSON.summary/1)
    }
  end
end
