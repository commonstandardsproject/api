defmodule CspApi.Schemas.Jurisdiction do
  @moduledoc "Port of `models/jurisdiction.rb`."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "jurisdictions" do
    field :title, :string
    field :url, :string
    field :type, :string
    field :status, :string
    field :submitterEmail, :string
    field :submitterName, :string
    field :submitterId, :string
  end

  @cast_fields ~w(id title url type status submitterEmail submitterName submitterId)a

  def changeset(j, attrs) do
    j
    |> cast(attrs, @cast_fields)
    |> validate_required([:title])
  end
end
