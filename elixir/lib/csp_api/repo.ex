defmodule CspApi.Repo do
  @moduledoc """
  Ecto repo backed by the `mongodb_ecto` adapter. The collection name for
  each schema is set explicitly with `schema "name"` on the schema module.
  """

  use Ecto.Repo,
    otp_app: :csp_api,
    adapter: Mongo.Ecto
end
