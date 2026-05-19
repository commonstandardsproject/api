defmodule CspApiWeb.JurisdictionsController do
  use CspApiWeb, :controller

  alias CspApi.Jurisdictions
  alias CspApiWeb.JurisdictionJSON

  def index(conn, _params) do
    user_id = current_user_id(conn)
    jurisdictions = Jurisdictions.list_all(user_id)
    json(conn, %{data: Enum.map(jurisdictions, &JurisdictionJSON.summary/1)})
  end

  def show(conn, %{"id" => id} = params) do
    hide_hidden? = parse_bool(params["hideHiddenSets"], true)

    case Jurisdictions.get(id, hide_hidden_sets: hide_hidden?) do
      nil -> json(conn, %{data: %{}})
      {j, sets} -> json(conn, %{data: JurisdictionJSON.full(j, sets)})
    end
  end

  defp current_user_id(conn) do
    case conn.assigns[:current_user] do
      %{id: id} -> id
      _ -> nil
    end
  end

  defp parse_bool(nil, default), do: default
  defp parse_bool("true", _), do: true
  defp parse_bool("false", _), do: false
  defp parse_bool(true, _), do: true
  defp parse_bool(false, _), do: false
  defp parse_bool(_, default), do: default
end
