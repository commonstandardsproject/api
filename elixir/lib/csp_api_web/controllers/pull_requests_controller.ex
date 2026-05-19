defmodule CspApiWeb.PullRequestsController do
  use CspApiWeb, :controller

  alias CspApi.PullRequests
  alias CspApiWeb.PullRequestJSON

  def index(conn, _params) do
    prs = PullRequests.list_active()
    json(conn, %{data: Enum.map(prs, &PullRequestJSON.full/1)})
  end

  def for_user(conn, %{"user_id" => user_id}) do
    prs = PullRequests.list_for_user(user_id)
    json(conn, %{data: Enum.map(prs, &PullRequestJSON.summary/1)})
  end

  def show(conn, %{"id" => id}) do
    case PullRequests.get(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      pr -> json(conn, %{data: PullRequestJSON.full(pr)})
    end
  end

  def create(conn, params) do
    user = conn.assigns[:current_user]
    pr = PullRequests.create(user, params["standardSetId"] || params["standard_set_id"])
    json(conn, %{data: PullRequestJSON.full(pr)})
  end

  def user_update(conn, %{"id" => id} = params) do
    user = conn.assigns[:current_user]

    case PullRequests.get(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      pr ->
        if PullRequests.can_edit?(pr, user) do
          {:ok, updated} = PullRequests.user_update(id, params["data"] || %{})
          json(conn, %{data: PullRequestJSON.full(updated)})
        else
          send_resp(conn, 401, "")
        end
    end
  end

  def submit(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]

    case PullRequests.get(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      pr ->
        if PullRequests.can_edit?(pr, user) do
          updated =
            PullRequests.change_status(
              id,
              "approval-requested",
              "Thanks so much! We'll take a look and get back to you in the next week (if not sooner)",
              true
            )

          json(conn, %{data: PullRequestJSON.full(updated)})
        else
          send_resp(conn, 401, "")
        end
    end
  end

  def change_status(conn, %{"id" => id, "status" => status} = params) do
    user = conn.assigns[:current_user]

    if Map.get(user, "isCommitter") == true do
      case PullRequests.change_status(id, status, params["message"], true) do
        {:error, :invalid_status} ->
          # Ruby behavior: silently returns the unchanged PR with 200.
          json(conn, %{data: PullRequestJSON.full(PullRequests.get(id))})

        pr ->
          json(conn, %{data: PullRequestJSON.full(pr)})
      end
    else
      send_resp(conn, 401, "")
    end
  end

  def comment(conn, %{"id" => id, "comment" => comment}) do
    user = conn.assigns[:current_user]

    case PullRequests.get(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      pr ->
        if PullRequests.can_edit?(pr, user) do
          updated = PullRequests.add_comment(pr, comment, user)
          json(conn, %{data: PullRequestJSON.full(updated)})
        else
          send_resp(conn, 401, "")
        end
    end
  end
end
