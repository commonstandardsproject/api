defmodule CspApi.Schemas.Activity do
  @moduledoc "Port of `models/activity.rb`. Always embedded in a pull request."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :string
    field :createdAt, :utc_datetime
    field :type, :string
    field :status, :string
    field :title, :string
    field :userId, :string
    field :userName, :string
  end

  @cast_fields ~w(id createdAt type status title userId userName)a

  def changeset(a, attrs) do
    a
    |> cast(attrs, @cast_fields)
    |> validate_required([:type, :title, :createdAt])
  end
end
