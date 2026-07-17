defmodule CspApi.Schemas.StandardDocument do
  @moduledoc "Port of the `standard_documents` collection — opaque inner payloads."

  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}

  schema "standard_documents" do
    field :document, :map, default: %{}
    field :documentMeta, :map, default: %{}
    field :standardSetQueries, {:array, :map}, default: []
  end
end
