defmodule CspApiWeb.StandardDocumentsController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.MongoX
  alias CspApiWeb.Schemas

  tags ["StandardDocuments"]

  operation :show,
    summary: "Get a standard document",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"Standard document", "application/json", Schemas.StandardDocument}
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
      nil -> json(conn, %{})
      doc -> json(conn, %{id: doc["_id"], document: doc["document"], documentMeta: doc["documentMeta"], standardSetQueries: doc["standardSetQueries"]})
    end
  end
end
