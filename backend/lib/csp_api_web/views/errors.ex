defmodule CspApiWeb.Errors.JSON do
  @moduledoc "Error envelope for 4xx/5xx responses."
  use Ecto.Schema
  use CspApiWeb.View

  # Error responses have no `:id`.
  @primary_key false
  embedded_schema do
    field :error, :string
    field :errors, :map
  end
end
