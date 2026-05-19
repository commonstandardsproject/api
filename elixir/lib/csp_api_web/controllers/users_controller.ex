defmodule CspApiWeb.UsersController do
  use CspApiWeb, :controller

  alias CspApi.Users
  alias CspApiWeb.UserJSON

  def signed_in(conn, %{"profile" => profile}) do
    user = Users.upsert_signed_in(profile)
    json(conn, %{data: UserJSON.full(user)})
  end

  def show(conn, %{"email" => email}) do
    case Users.by_email(email) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "User not found"})
      user ->
        prs = CspApi.PullRequests.list_for_user(user["_id"])
        json(conn, %{data: UserJSON.full(Map.put(user, "pullRequests", prs))})
    end
  end

  def set_allowed_origins(conn, %{"id" => id, "data" => data}) when is_list(data) do
    user = Users.set_allowed_origins(id, data)
    json(conn, %{data: UserJSON.full(user)})
  end
end
