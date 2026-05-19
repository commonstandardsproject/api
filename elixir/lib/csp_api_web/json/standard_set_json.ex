defmodule CspApiWeb.StandardSetJSON do
  @moduledoc """
  Mirrors `api/entities/standard_set.rb` and
  `api/entities/standard_set_summary.rb` from the Ruby app.
  """

  @doc "List-item shape used inside the jurisdiction response."
  def summary(s) do
    %{
      "id" => s["_id"] || s["id"],
      "title" => s["title"],
      "subject" => s["subject"],
      "educationLevels" => s["educationLevels"] || [],
      "document" => s["document"] || %{}
    }
  end

  @doc "Detailed shape for `GET /api/v1/standard_sets/:id`."
  def full(s, opts \\ []) do
    as_array? = Keyword.get(opts, :as_array, false)
    standards = s["standards"] || (if as_array?, do: [], else: %{})

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
      "standards" => standards
    }
  end
end
