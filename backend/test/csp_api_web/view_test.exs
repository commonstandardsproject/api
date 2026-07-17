defmodule CspApiWeb.ViewTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.Schema

  # ── Test views ─────────────────────────────────────────────────────

  defmodule SimpleJSON do
    use Ecto.Schema
    use CspApiWeb.View

    embedded_schema do
      field :title, :string
      field :type, :string
    end
  end

  defmodule InnerJSON do
    use Ecto.Schema
    use CspApiWeb.View

    embedded_schema do
      field :name, :string
    end
  end

  defmodule WithEmbedJSON do
    use Ecto.Schema
    use CspApiWeb.View

    embedded_schema do
      field :title, :string
      embeds_one :child, InnerJSON
      embeds_many :children, InnerJSON
    end
  end

  defmodule TypedJSON do
    use Ecto.Schema
    use CspApiWeb.View

    embedded_schema do
      field :count, :integer
      field :score, :float
      field :active, :boolean
      field :tags, {:array, :string}
      field :metadata, :map
      field :created_at, :utc_datetime
    end
  end

  # ── data/1 — source struct → wire map ──────────────────────────────

  describe "data/1" do
    test "renders only the declared fields, in field order" do
      source = %{id: "ABC", title: "Alabama", type: "state", extra: "ignored"}
      assert SimpleJSON.data(source) == %{id: "ABC", title: "Alabama", type: "state"}
    end

    test "missing fields on the source come out as nil (extra keys are fine)" do
      assert SimpleJSON.data(%{id: "X"}) == %{id: "X", title: nil, type: nil}
    end

    test "string-keyed sources work too (raw Mongo docs etc.)" do
      source = %{"id" => "X", "title" => "Alabama", "type" => "state"}
      assert SimpleJSON.data(source) == %{id: "X", title: "Alabama", type: "state"}
    end

    test "recurses through embeds_one via the related view" do
      child = %{id: "C1", name: "child"}
      source = %{id: "P", title: "parent", child: child, children: []}
      assert WithEmbedJSON.data(source) == %{
               id: "P",
               title: "parent",
               child: %{id: "C1", name: "child"},
               children: []
             }
    end

    test "recurses through embeds_many via the related view" do
      children = [%{id: "C1", name: "a"}, %{id: "C2", name: "b"}]
      source = %{id: "P", title: "parent", child: nil, children: children}
      assert WithEmbedJSON.data(source) == %{
               id: "P",
               title: "parent",
               # Missing-source embeds_one becomes `{}` to match Ruby
               # grape-entity's `(x || {}).to_hash` behavior.
               child: %{},
               children: [%{id: "C1", name: "a"}, %{id: "C2", name: "b"}]
             }
    end

    test "nil embeds_one becomes %{} and nil embeds_many becomes []" do
      source = %{id: "P", title: "parent"}
      assert WithEmbedJSON.data(source) == %{
               id: "P",
               title: "parent",
               child: %{},
               children: []
             }
    end

    test "nil :map fields render as %{} and nil arrays as []" do
      defmodule MapFieldJSON do
        use Ecto.Schema
        use CspApiWeb.View

        embedded_schema do
          field :meta, :map
          field :tags, {:array, :string}
        end
      end

      assert MapFieldJSON.data(%{id: "X"}) == %{id: "X", meta: %{}, tags: []}
    end
  end

  # ── data/2 — assigns override source ────────────────────────────────

  describe "data/2" do
    test "assigns win over the source struct" do
      source = %{id: "from_source", title: "src", type: "state"}
      assigns = %{title: "from_assigns"}
      assert SimpleJSON.data(source, assigns) ==
               %{id: "from_source", title: "from_assigns", type: "state"}
    end

    test "assigns supply fields the source doesn't have" do
      source = %{id: "P", title: "parent"}
      assigns = %{children: [%{id: "C1", name: "x"}], child: nil}
      assert WithEmbedJSON.data(source, assigns) == %{
               id: "P",
               title: "parent",
               child: %{},
               children: [%{id: "C1", name: "x"}]
             }
    end
  end

  # ── schema/0 — single-record envelope ───────────────────────────────

  describe "schema/0" do
    test "returns {data: <inner>} envelope with the inner record" do
      assert %Schema{
               type: :object,
               required: [:data],
               properties: %{data: inner}
             } = SimpleJSON.schema()

      assert %Schema{
               title: "Simple",
               type: :object,
               required: required,
               properties: properties
             } = inner

      assert MapSet.new(required) == MapSet.new([:id, :title, :type])
      assert properties.id == %Schema{type: :string}
      assert properties.title == %Schema{type: :string}
      assert properties.type == %Schema{type: :string}
    end

    test "maps Ecto types to OpenAPI fragments" do
      %Schema{properties: %{data: %Schema{properties: props}}} = TypedJSON.schema()

      assert props.id == %Schema{type: :string}
      assert props.count == %Schema{type: :integer}
      assert props.score == %Schema{type: :number, format: :double}
      assert props.active == %Schema{type: :boolean}
      assert props.tags == %Schema{type: :array, items: %Schema{type: :string}}
      assert props.metadata == %Schema{type: :object}
      assert props.created_at == %Schema{type: :string, format: :"date-time"}
    end

    test "embedded_one inlines the related view's inner schema" do
      %Schema{properties: %{data: %Schema{properties: props}}} = WithEmbedJSON.schema()

      assert %Schema{
               type: :object,
               title: "Inner",
               required: required,
               properties: inner_props
             } = props.child

      assert MapSet.new(required) == MapSet.new([:id, :name])
      assert inner_props.id == %Schema{type: :string}
      assert inner_props.name == %Schema{type: :string}
    end

    test "embedded_many wraps the related view's inner schema in an array" do
      %Schema{properties: %{data: %Schema{properties: props}}} = WithEmbedJSON.schema()

      assert %Schema{type: :array, items: %Schema{title: "Inner"}} = props.children
    end
  end

  # ── list_schema/0 — list-of-records envelope ────────────────────────

  describe "list_schema/0" do
    test "returns {data: [<inner>]} envelope" do
      assert %Schema{
               type: :object,
               required: [:data],
               properties: %{data: %Schema{type: :array, items: items}}
             } = SimpleJSON.list_schema()

      assert %Schema{title: "Simple"} = items
    end
  end
end
