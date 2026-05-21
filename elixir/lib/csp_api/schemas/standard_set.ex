defmodule CspApi.Schemas.StandardSet do
  @moduledoc """
  Port of `models/standard_set.rb`. Sub-documents use `embeds_one` with
  explicit `@primary_key {:id, :string, autogenerate: false}` so the
  Mongo adapter stores `id` as `id` (it only remaps unkeyed `:id` fields
  to `_id`). The `standards` collection is `:map` because the Ruby model
  is `Hash[id => Standard]` and that's how it's stored on disk.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__.{Jurisdiction, CspStatus, License, Document}

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

    embeds_one :document, Document, on_replace: :update
    embeds_one :jurisdiction, Jurisdiction, on_replace: :update
    embeds_one :cspStatus, CspStatus, on_replace: :update
    embeds_one :license, License, on_replace: :update
  end

  @cast_fields ~w(
    id title subject normalizedSubject educationLevels standards
    standardsCount version createdAt updatedAt
  )a

  def changeset(set, attrs) do
    set
    |> cast(attrs, @cast_fields)
    |> cast_embed(:document)
    |> cast_embed(:jurisdiction)
    |> cast_embed(:cspStatus)
    |> cast_embed(:license)
    |> validate_required([:title, :subject])
    |> validate_education_levels()
  end

  defp validate_education_levels(changeset) do
    case get_field(changeset, :educationLevels) do
      nil -> changeset
      [] -> changeset
      levels ->
        if Enum.all?(levels, &(&1 in @education_levels)) do
          changeset
        else
          add_error(changeset, :educationLevels, "contains unknown level")
        end
    end
  end

  defmodule Jurisdiction do
    use Ecto.Schema
    import Ecto.Changeset

    # Explicit string `:id` primary key — without this, mongodb_ecto
    # would treat the `id` field as the embedded doc's auto-renamed
    # primary key and store it as `_id`, breaking `jurisdiction.id`
    # filters and the wire format the Ruby app reads.
    @primary_key {:id, :string, autogenerate: false}
    @derive {Jason.Encoder, only: [:id, :title]}
    embedded_schema do
      field :title, :string
    end

    def changeset(j, attrs) do
      j |> cast(attrs, [:id, :title]) |> validate_required([:id, :title])
    end
  end

  defmodule Document do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :string, autogenerate: false}
    @derive {Jason.Encoder,
             only: [:id, :title, :asnIdentifier, :publicationStatus, :sourceURL, :valid]}
    embedded_schema do
      field :title, :string
      field :asnIdentifier, :string
      field :publicationStatus, :string
      field :sourceURL, :string
      field :valid, :string
    end

    def changeset(d, attrs),
      do: cast(d, attrs, [:id, :title, :asnIdentifier, :publicationStatus, :sourceURL, :valid])
  end

  defmodule CspStatus do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    @derive {Jason.Encoder, only: [:value, :notes]}
    embedded_schema do
      field :value, :string, default: "visible"
      field :notes, :string
    end

    def changeset(c, attrs), do: cast(c, attrs, [:value, :notes])
  end

  defmodule License do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    @derive {Jason.Encoder, only: [:title, :URL, :rightsHolder]}
    embedded_schema do
      field :title, :string, default: "CC BY 4.0 US"
      field :URL, :string, default: "http://creativecommons.org/licenses/by/4.0/us/"
      field :rightsHolder, :string, default: "Common Curriculum, Inc."
    end

    def changeset(l, attrs), do: cast(l, attrs, [:title, :URL, :rightsHolder])
  end
end
