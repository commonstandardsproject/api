defmodule CspApiWeb.StandardDocumentsController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.MongoX
  alias CspApiWeb.StandardDocuments.DetailJSON

  tags ["StandardDocuments"]

  operation :show,
    summary: "Get a standard document",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"A standard document with its standards and metadata", "application/json", DetailJSON.schema()}
    ]

  def show(conn, %{"id" => id}) do
    case MongoX.find_one(
           "standard_documents",
           %{"_id" => id},
           projection: %{
             "_id" => 1,
             "document" => 1,
             "documentMeta" => 1,
             "standardSetQueries" => 1
           }
         ) do
      nil ->
        json(conn, %{})

      doc ->
        json(conn, %{data: DetailJSON.data(MongoX.normalize_id(doc))})
    end
  end
end
