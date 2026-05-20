defmodule CspApi.Schemas.StandardSet do
  @moduledoc """
  Port of `models/standard_set.rb`. Nested data is captured with
  `embeds_one`; the `standards` collection stays as a `:map` keyed by id
  because that's how the Ruby app and the existing Mongo documents store
  it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  @education_levels ~w(
    Pre-K K 01 02 03 04 05 06 07 08 09 10 11 12
    VocationalTraining ProfessionalEducation-Development Graduate
    HigherEducation Undergraduate-UpperDivision Undergraduate-LowerDivision
    AdultEducation LifeLongLearning
  )

  def education_levels, do: @education_levels

  schema "standard_sets" do
    field :title, :string, default: ""
    field :subject, :string, default: ""
    field :normalizedSubject, :string
    field :educationLevels, {:array, :string}, default: []

    # Standards are stored as a Hash[id => Standard] (matching the Ruby
    # model). The hierarchy walker in `CspApi.Hierarchy` populates
    # `ancestorIds`/`parentId` on read.
    field :standards, :map, default: %{}
    field :standardsCount, :integer, default: 0
    field :version, :integer, default: 1
    field :createdAt, :utc_datetime
    field :updatedAt, :utc_datetime
    field :document, :map, default: %{}

    # These are stored as plain :map fields rather than embeds_one because
    # mongodb_ecto remaps an embedded schema's :id field to _id, which would
    # break wire-format compatibility with the Ruby app (which writes
    # `jurisdiction: { id: ..., title: ... }`).
    field :jurisdiction, :map, default: %{}
    field :cspStatus, :map, default: %{"value" => "visible"}
    field :license, :map, default: %{"title" => "CC BY 4.0 US", "URL" => "http://creativecommons.org/licenses/by/4.0/us/", "rightsHolder" => "Common Curriculum, Inc."}
  end

  @cast_fields ~w(
    id title subject normalizedSubject educationLevels standards
    standardsCount version createdAt updatedAt document
    jurisdiction cspStatus license
  )a

  def changeset(set, attrs) do
    set
    |> cast(attrs, @cast_fields)
    |> stringify_map_keys([:jurisdiction, :cspStatus, :license, :document])
    |> validate_required([:title, :subject])
    |> validate_education_levels()
  end

  # Embedded sub-documents are stored with string keys, matching the
  # wire format the Ruby app reads/writes and what arrives via JSON.
  # Without this, atom keys get remapped (most notably :id → _id) by
  # the Mongo adapter, breaking filters like `jurisdiction.id`.
  defp stringify_map_keys(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      case get_change(cs, field) do
        nil -> cs
        map when is_map(map) -> put_change(cs, field, stringify(map))
        _ -> cs
      end
    end)
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify(v)}
      {k, v} -> {k, stringify(v)}
    end)
  end

  defp stringify(other), do: other

  defp validate_education_levels(changeset) do
    case get_field(changeset, :educationLevels) do
      nil ->
        changeset

      [] ->
        changeset

      levels ->
        if Enum.all?(levels, &(&1 in @education_levels)) do
          changeset
        else
          add_error(changeset, :educationLevels, "contains unknown level")
        end
    end
  end

end
