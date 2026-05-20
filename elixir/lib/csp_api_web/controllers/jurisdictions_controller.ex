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

  def create(conn, %{"jurisdiction" => attrs}) when is_map(attrs) do
    submitter_id =
      case conn.assigns[:current_user] do
        %{id: id} -> id
        _ -> nil
      end

    case Jurisdictions.create_pending(atom_keyed(attrs), submitter_id) do
      {:ok, j} ->
        json(conn, %{data: JurisdictionJSON.summary(j)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset_errors(cs)})
    end
  end

  defp atom_keyed(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      kv -> kv
    end)
  end

  defp changeset_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
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
