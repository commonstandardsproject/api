defmodule CspApiWeb.StandardDocumentsController do
  use CspApiWeb, :controller

  alias CspApi.MongoX

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
