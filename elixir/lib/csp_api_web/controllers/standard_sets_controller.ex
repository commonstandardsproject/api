defmodule CspApiWeb.StandardSetsController do
  use CspApiWeb, :controller

  alias CspApi.StandardSets
  alias CspApiWeb.StandardSetJSON

  def show(conn, %{"id" => id} = params) do
    as_array? = params["standardsAsArray"] in [true, "true"]

    set = if as_array?, do: StandardSets.get_with_array(id), else: StandardSets.get(id)

    case set do
      nil -> json(conn, %{data: %{}})
      set -> json(conn, %{data: StandardSetJSON.full(set)})
    end
  end
end
