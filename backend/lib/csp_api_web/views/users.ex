defmodule CspApiWeb.Users.ShowJSON do
  @moduledoc """
  Shape returned by the `/users/:email`, `/users/signed_in`, and
  `/users/:id/allowed_origins` endpoints.
  """
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :profile, :map
    field :email, :string
    field :apiKey, :string
    field :algoliaApiKey, :string
    field :allowedOrigins, {:array, :string}
    # `pullRequests` is computed at the controller (a join into
    # PullRequests.list_for_user/1) and supplied via `data/2`'s assigns.
    field :pullRequests, {:array, :map}
    field :isCommitter, :boolean
  end
end
