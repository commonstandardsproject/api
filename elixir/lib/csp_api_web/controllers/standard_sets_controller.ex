defmodule CspApiWeb.StandardSetsController do
  use CspApiWeb, :controller

  alias CspApi.StandardSets
  alias CspApiWeb.StandardSetJSON

  def show(conn, %{"id" => id} = params) do
    as_array? = params["standardsAsArray"] in [true, "true"]

    standard_set =
      if as_array?, do: StandardSets.get_with_array(id), else: StandardSets.get(id)

    case standard_set do
      nil ->
        # The Ruby app returns 200 with an empty data object when not found.
        json(conn, %{data: %{}})

      set ->
        json(conn, %{data: StandardSetJSON.full(set, as_array: as_array?)})
    end
  end
end
