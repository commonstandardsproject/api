defmodule CspApiWeb.StandardDocuments.SummaryJSON do
  @moduledoc "Lightweight reference to a standard document — used inside a Jurisdiction summary."
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :title, :string
    field :asnIdentifier, :string
    field :publicationStatus, :string
    field :sourceURL, :string
    field :valid, :string
  end
end

defmodule CspApiWeb.StandardDocuments.DetailJSON do
  @moduledoc "Response shape for `GET /api/v1/standard_documents/:id`."
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :document, :map
    field :documentMeta, :map
    field :standardSetQueries, {:array, :map}
  end
end
