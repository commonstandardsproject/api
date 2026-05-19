defmodule CspApi.Schemas.User do
  @moduledoc "Port of `models/user.rb`."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :email, :string
    field :apiKey, :string
    field :algoliaApiKey, :string
    field :profile, :map, default: %{}
    field :allowedOrigins, {:array, :string}, default: []
    field :isCommitter, :boolean, default: false
    field :requestCount, :integer, default: 0
    field :signInCount, :integer, default: 0
  end

  @cast_fields ~w(
    id email apiKey algoliaApiKey profile allowedOrigins
    isCommitter requestCount signInCount
  )a

  def changeset(u, attrs) do
    u
    |> cast(attrs, @cast_fields)
    |> validate_required([:email])
  end

  @doc """
  Changeset for the `POST /users/signed_in` payload. The Ruby endpoint
  trusts whatever profile shape the client sends — we don't over-constrain
  here either, but we do require an email.
  """
  def signed_in_changeset(u, %{} = profile_outer) do
    profile = profile_outer["profile"] || profile_outer[:profile] || %{}

    attrs = %{
      email: profile["email"] || profile[:email],
      profile: profile
    }

    u
    |> cast(attrs, [:email, :profile])
    |> validate_required([:email])
  end
end
