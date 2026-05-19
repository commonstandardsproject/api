defmodule CspApiWeb.UsersController do
  use CspApiWeb, :controller

  alias CspApi.{Users, PullRequests}
  alias CspApiWeb.UserJSON

  def signed_in(conn, params) do
    user = Users.upsert_signed_in(params)
    json(conn, %{data: UserJSON.show(user)})
  end

  def show(conn, %{"email" => email}) do
    case Users.by_email(email) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        prs = PullRequests.list_for_user(user.id)
        json(conn, %{data: UserJSON.show(Map.put(user, :pullRequests, prs))})
    end
  end

  def set_allowed_origins(conn, %{"id" => id, "data" => data}) when is_list(data) do
    case Users.set_allowed_origins(id, data) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "User not found"})
      user -> json(conn, %{data: UserJSON.show(user)})
    end
  end
end
