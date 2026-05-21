defmodule CspApiWeb.StandardDocumentsController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.Repo
  alias CspApi.Schemas.StandardDocument
  alias CspApiWeb.StandardDocuments.DetailJSON

  tags ["StandardDocuments"]

  operation :show,
    summary: "Get a standard document",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"A standard document with its standards and metadata", "application/json", DetailJSON.schema()}
    ]

  def show(conn, %{"id" => id}) do
    case Repo.get(StandardDocument, id) do
      nil -> json(conn, %{})
      doc -> json(conn, %{data: DetailJSON.data(doc)})
    end
  end
end
