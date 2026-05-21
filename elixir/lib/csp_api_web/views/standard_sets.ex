defmodule CspApiWeb.StandardSets.SummaryJSON do
  @moduledoc """
  Lightweight reference to a standard set — used inside a Jurisdiction's
  `standardSets` list and inside the embedded `standardSet` on a PR.
  """
  use Ecto.Schema
  use CspApiWeb.View

  alias CspApiWeb.StandardDocuments.SummaryJSON, as: DocumentSummary

  embedded_schema do
    field :title, :string
    field :subject, :string
    field :educationLevels, {:array, :string}
    embeds_one :document, DocumentSummary
  end
end

defmodule CspApiWeb.StandardSets.DetailJSON do
  @moduledoc "Full `GET /api/v1/standard_sets/:id` response shape."
  use Ecto.Schema
  use CspApiWeb.View

  alias CspApiWeb.StandardDocuments.SummaryJSON, as: DocumentSummary

  embedded_schema do
    field :title, :string
    field :subject, :string
    field :normalizedSubject, :string
    field :educationLevels, {:array, :string}
    # cspStatus / license / jurisdiction are passed through as opaque maps:
    # consumers depend on whatever keys Mongo has, which we don't want to
    # collapse into a typed schema. `standards` is the Hash[id => Standard]
    # map (or an array when ?standardsAsArray=true) — we render it as a
    # generic object/array since the polymorphism isn't expressible in
    # OpenAPI without a per-field override.
    field :cspStatus, :map
    field :license, :map
    field :jurisdiction, :map
    embeds_one :document, DocumentSummary
    field :standards, :map
  end
end
