defmodule CspApiWeb.View do
  @moduledoc """
  Bridges an Ecto `embedded_schema` into an OpenAPI 3.0 response schema
  and a JSON renderer.

  A View module is the wire-format declaration for one response shape.
  It is an `Ecto.Schema` (no database) plus a `use CspApiWeb.View` call
  that injects three runtime functions:

    * `data/1` / `data/2` — given a source struct (and an optional
      `assigns` map for values not on the struct), returns a plain map
      with the same shape as the embedded_schema.

    * `schema/0` — returns an `%OpenApiSpex.Schema{}` describing the
      envelope-wrapped single-record response `{"data": <record>}`.

    * `list_schema/0` — same, for `{"data": [<record>, …]}`.

  ## Example

      defmodule CspApiWeb.Jurisdictions.SummaryJSON do
        use Ecto.Schema
        use CspApiWeb.View

        embedded_schema do
          field :id, :string
          field :title, :string
          field :type, :string
        end
      end

  Then in the controller:

      operation :show,
        responses: [
          ok: {"A jurisdiction", "application/json", SummaryJSON}
        ]

      def show(conn, %{"id" => id}) do
        j = Jurisdictions.get(id)
        json(conn, %{data: SummaryJSON.data(j)})
      end

  ## Embedded views

  Composing views works through Ecto's `embeds_one` / `embeds_many` as
  long as the related module is itself a View. The macro recognizes the
  related view and recurses through its `data/1` for rendering and
  inlines its `schema/0`'s inner record for the OpenAPI schema.

  ## Assigns

  Use `data/2` when the source struct doesn't carry one of the wire
  fields directly — e.g. a joined collection passed alongside the main
  struct. Values in `assigns` win over values on the source.

      DetailJSON.data(jurisdiction, %{standardSets: sets})
  """

  alias OpenApiSpex.Schema

  defmacro __using__(_opts) do
    quote do
      # Every wire response in this API has a string `:id` (Mongo `_id`)
      # — declare it as the primary key so individual views don't need to
      # repeat `field :id, :string`. Override with `@primary_key false` in
      # the view module if you really don't want one (e.g. error envelopes).
      @primary_key {:id, :string, autogenerate: false}
      @before_compile CspApiWeb.View
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def data(source, assigns \\ %{}) do
        CspApiWeb.View.__render__(__MODULE__, source, assigns)
      end

      def schema, do: CspApiWeb.View.__schema_envelope__(__MODULE__, :single)
      def list_schema, do: CspApiWeb.View.__schema_envelope__(__MODULE__, :list)
    end
  end

  # ────────────────────────────────────────────────────────────────────
  # Rendering: source struct + assigns → wire map

  @doc false
  def __render__(view_module, source, assigns) when is_map(assigns) do
    fields = view_module.__schema__(:fields)
    embeds = view_module.__schema__(:embeds)

    Enum.reduce(fields, %{}, fn field, acc ->
      raw =
        if Map.has_key?(assigns, field) do
          Map.get(assigns, field)
        else
          read_field(source, field)
        end

      Map.put(acc, field, render_field(view_module, field, raw, field in embeds))
    end)
  end

  # Source maps can be Ecto structs (atom keys only) or raw Mongo docs
  # (string keys). Try atom first, fall back to string. For the conventional
  # `:id` field, also accept Mongo's `"_id"` so raw documents from
  # `Mongo.Ecto.command/2` queries don't need pre-aliasing.
  defp read_field(source, field) when is_map(source) do
    string_key = Atom.to_string(field)

    cond do
      Map.has_key?(source, field) -> Map.get(source, field)
      Map.has_key?(source, string_key) -> Map.get(source, string_key)
      field == :id and Map.has_key?(source, "_id") -> Map.get(source, "_id")
      true -> nil
    end
  end

  defp render_field(view, field, nil, true) do
    # Ruby's grape-entity does `(doc[:x] || {}).to_hash` for embedded
    # subdocs — missing-from-source becomes `{}` (singular) or `[]`
    # (collection), not `null`. Match that.
    case view.__schema__(:embed, field) do
      %{cardinality: :one} -> %{}
      %{cardinality: :many} -> []
    end
  end

  defp render_field(view, field, nil, false) do
    case view.__schema__(:type, field) do
      :map -> %{}
      {:map, _} -> %{}
      {:array, _} -> []
      _ -> nil
    end
  end

  defp render_field(view, field, value, true) do
    %{related: related, cardinality: cardinality} = view.__schema__(:embed, field)

    case cardinality do
      :one -> related.data(value)
      :many -> Enum.map(value, &related.data/1)
    end
  end

  defp render_field(_view, _field, value, false), do: demap_struct(value)

  # Source data on a non-embed `:map` field can be either a raw Mongo map
  # (pass through) or an Ecto-loaded embedded struct (Jason can't encode
  # those). Recursively unwrap Ecto-style structs to plain maps; leave
  # date/time structs alone since Jason knows how to encode them.
  defp demap_struct(%mod{} = value)
       when mod in [DateTime, Date, NaiveDateTime, Time, Decimal, BSON.UTCDateTime, BSON.ObjectId] do
    value
  end

  defp demap_struct(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Map.new(fn {k, v} -> {k, demap_struct(v)} end)
  end

  defp demap_struct(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, demap_struct(v)} end)
  end

  defp demap_struct(list) when is_list(list) do
    Enum.map(list, &demap_struct/1)
  end

  defp demap_struct(other), do: other

  # ────────────────────────────────────────────────────────────────────
  # Schema: reflect Ecto types into an OpenAPI envelope

  @doc false
  def __schema_envelope__(view_module, variant) do
    inner = build_inner_schema(view_module)

    case variant do
      :single ->
        %Schema{
          type: :object,
          properties: %{data: inner},
          required: [:data]
        }

      :list ->
        %Schema{
          type: :object,
          properties: %{data: %Schema{type: :array, items: inner}},
          required: [:data]
        }
    end
  end

  defp build_inner_schema(view_module) do
    fields = view_module.__schema__(:fields)
    embeds = view_module.__schema__(:embeds)

    properties =
      Enum.reduce(fields, %{}, fn field, acc ->
        Map.put(acc, field, field_schema(view_module, field, field in embeds))
      end)

    %Schema{
      title: title_of(view_module),
      type: :object,
      properties: properties,
      required: fields
    }
  end

  defp field_schema(view, field, true) do
    %{related: related, cardinality: cardinality} = view.__schema__(:embed, field)
    related_inner = build_inner_schema(related)

    case cardinality do
      :one -> related_inner
      :many -> %Schema{type: :array, items: related_inner}
    end
  end

  defp field_schema(view, field, false) do
    type = view.__schema__(:type, field)
    type_to_schema(type)
  end

  defp title_of(view_module) do
    view_module
    |> Module.split()
    |> List.last()
    |> String.replace_suffix("JSON", "")
  end

  # ────────────────────────────────────────────────────────────────────
  # Ecto type → OpenAPI schema fragment

  defp type_to_schema(:string), do: %Schema{type: :string}
  defp type_to_schema(:integer), do: %Schema{type: :integer}
  defp type_to_schema(:float), do: %Schema{type: :number, format: :double}
  defp type_to_schema(:boolean), do: %Schema{type: :boolean}
  defp type_to_schema(:binary), do: %Schema{type: :string, format: :binary}
  defp type_to_schema(:binary_id), do: %Schema{type: :string, format: :uuid}
  defp type_to_schema(:id), do: %Schema{type: :integer}
  defp type_to_schema(:decimal), do: %Schema{type: :string, format: :decimal}
  defp type_to_schema(:date), do: %Schema{type: :string, format: :date}
  defp type_to_schema(:time), do: %Schema{type: :string, format: :time}
  defp type_to_schema(:utc_datetime), do: %Schema{type: :string, format: :"date-time"}
  defp type_to_schema(:utc_datetime_usec), do: %Schema{type: :string, format: :"date-time"}
  defp type_to_schema(:naive_datetime), do: %Schema{type: :string, format: :"date-time"}
  defp type_to_schema(:naive_datetime_usec), do: %Schema{type: :string, format: :"date-time"}
  defp type_to_schema(:map), do: %Schema{type: :object}
  defp type_to_schema({:map, inner}), do: %Schema{type: :object, additionalProperties: type_to_schema(inner)}
  defp type_to_schema({:array, inner}), do: %Schema{type: :array, items: type_to_schema(inner)}

  defp type_to_schema({:parameterized, {Ecto.Enum, %{mappings: mappings}}}) do
    %Schema{type: :string, enum: mappings |> Keyword.keys() |> Enum.map(&Atom.to_string/1)}
  end

  defp type_to_schema(_unknown), do: %Schema{}
end
