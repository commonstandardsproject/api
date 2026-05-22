defmodule CspApiWeb.StandardSetsController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.StandardSets
  alias CspApiWeb.StandardSets.DetailJSON

  tags ["StandardSets"]

  operation :show,
    summary: "Get a standard set",
    parameters: [
      id: [in: :path, required: true, type: :string],
      standardsAsArray: [
        in: :query,
        required: false,
        type: :boolean,
        description: "Return `standards` as an ordered list (true) or as an object keyed by id (default)."
      ]
    ],
    responses: [
      ok: {"A full standard set including its nested standards", "application/json", DetailJSON.schema()}
    ]

  def show(conn, %{"id" => id} = params) do
    as_array? = params["standardsAsArray"] in [true, "true"]

    set = if as_array?, do: StandardSets.get_with_array(id), else: StandardSets.get(id)

    case set do
      nil -> json(conn, %{data: %{}})
      set -> json(conn, %{data: DetailJSON.data(set)})
    end
  end
end
