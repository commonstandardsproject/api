defmodule CspApiWeb.Jurisdictions.SummaryJSON do
  @moduledoc "Shape for entries in `GET /api/v1/jurisdictions`."
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :title, :string
    field :type, :string
  end
end

defmodule CspApiWeb.Jurisdictions.DetailJSON do
  @moduledoc "Shape for `GET /api/v1/jurisdictions/:id` — includes nested standard sets."
  use Ecto.Schema
  use CspApiWeb.View

  alias CspApiWeb.StandardSets.SummaryJSON, as: StandardSetSummary

  embedded_schema do
    field :title, :string
    field :type, :string
    embeds_many :standardSets, StandardSetSummary
  end
end
