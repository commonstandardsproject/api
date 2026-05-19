defmodule CspApiWeb.StandardSetJSON do
  @moduledoc "Port of `api/entities/standard_set.rb` and `standard_set_summary.rb`."

  alias CspApi.Schemas.StandardSet

  def summary(%StandardSet{} = s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "subject" => s.subject,
      "educationLevels" => s.educationLevels || [],
      "document" => s.document || %{}
    }
  end

  def summary(s) when is_map(s) do
    %{
      "id" => s["_id"] || s["id"],
      "title" => s["title"],
      "subject" => s["subject"],
      "educationLevels" => s["educationLevels"] || [],
      "document" => s["document"] || %{}
    }
  end

  def full(%StandardSet{} = s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "subject" => s.subject,
      "normalizedSubject" => s.normalizedSubject,
      "educationLevels" => s.educationLevels || [],
      "cspStatus" => embedded(s.cspStatus),
      "license" => embedded(s.license),
      "document" => s.document || %{},
      "jurisdiction" => embedded(s.jurisdiction),
      "standards" => s.standards
    }
  end

  # Rendering a PR's embedded standardSet — a raw map, not a struct.
  def full(s) when is_map(s) do
    %{
      "id" => s["_id"] || s["id"],
      "title" => s["title"],
      "subject" => s["subject"],
      "normalizedSubject" => s["normalizedSubject"],
      "educationLevels" => s["educationLevels"] || [],
      "cspStatus" => s["cspStatus"] || %{},
      "license" => s["license"] || %{},
      "document" => s["document"] || %{},
      "jurisdiction" => s["jurisdiction"] || %{},
      "standards" => s["standards"] || %{}
    }
  end

  defp embedded(nil), do: %{}
  defp embedded(%_{} = struct), do: Map.from_struct(struct)
  defp embedded(map) when is_map(map), do: map
end
