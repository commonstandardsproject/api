defmodule CspApiWeb.UsersController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.{Users, PullRequests}
  alias CspApiWeb.Errors
  alias CspApiWeb.Users.ShowJSON

  tags ["Users"]

  operation :signed_in,
    summary: "Upsert the currently-signed-in user",
    description:
      "Called by the editor app after Auth0 login. Creates the user " <>
        "row if missing, otherwise refreshes the cached profile.",
    request_body:
      {"User profile fields", "application/json",
       %OpenApiSpex.Schema{type: :object, additionalProperties: true}},
    responses: [ok: {"The signed-in user with API keys and allowed origins", "application/json", ShowJSON.schema()}]

  def signed_in(conn, params) do
    user = Users.upsert_signed_in(params)
    json(conn, %{data: ShowJSON.data(user, %{pullRequests: []})})
  end

  operation :show,
    summary: "Look up a user by email",
    parameters: [email: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"The user with API keys, allowed origins, and pull requests", "application/json", ShowJSON.schema()},
      not_found: {"User not found", "application/json", Errors.JSON.schema()}
    ]

  def show(conn, %{"email" => email}) do
    case Users.by_email(email) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        prs = PullRequests.list_for_user(user.id)
        json(conn, %{data: ShowJSON.data(user, %{pullRequests: prs})})
    end
  end

  operation :set_allowed_origins,
    summary: "Replace a user's allowed CORS origins",
    parameters: [id: [in: :path, required: true, type: :string]],
    request_body:
      {"List of origins", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{
           data: %OpenApiSpex.Schema{
             type: :array,
             items: %OpenApiSpex.Schema{type: :string}
           }
         },
         required: [:data]
       }},
    responses: [
      ok: {"The user with the updated allowed origins", "application/json", ShowJSON.schema()},
      not_found: {"User not found", "application/json", Errors.JSON.schema()}
    ]

  def set_allowed_origins(conn, %{"id" => id, "data" => data}) when is_list(data) do
    case Users.set_allowed_origins(id, data) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "User not found"})
      user -> json(conn, %{data: ShowJSON.data(user, %{pullRequests: []})})
    end
  end
end
