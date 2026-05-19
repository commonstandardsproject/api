defmodule CspApiWeb.PullRequestsController do
  use CspApiWeb, :controller

  alias CspApi.PullRequests
  alias CspApiWeb.JSON

  def index(conn, _params) do
    prs = PullRequests.list_active()
    json(conn, %{data: Enum.map(prs, &JSON.pull_request_full/1)})
  end

  def for_user(conn, %{"user_id" => user_id}) do
    prs = PullRequests.list_for_user(user_id)
    json(conn, %{data: Enum.map(prs, &JSON.pull_request_summary/1)})
  end

  def show(conn, %{"id" => id}) do
    case PullRequests.get(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      pr -> json(conn, %{data: JSON.pull_request_full(pr)})
    end
  end

  def create(conn, params) do
    user = conn.assigns[:current_user]
    standard_set_id = params["standardSetId"] || params["standard_set_id"]

    pr =
      if is_binary(standard_set_id) and standard_set_id != "" do
        PullRequests.create_forked(user, standard_set_id)
      else
        PullRequests.create_blank(user)
      end

    json(conn, %{data: JSON.pull_request_full(pr)})
  end

  def user_update(conn, %{"id" => id} = params) do
    user = conn.assigns[:current_user]

    with %{} = pr <- PullRequests.get(id),
         true <- PullRequests.can_edit?(pr, user) do
      case PullRequests.user_update(id, params["data"] || %{}) do
        {:ok, updated} ->
          json(conn, %{data: JSON.pull_request_full(updated)})

        {:error, %Ecto.Changeset{} = cs} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: changeset_errors(cs)})
      end
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      false -> send_resp(conn, 401, "")
    end
  end

  def submit(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]

    with %{} = pr <- PullRequests.get(id),
         true <- PullRequests.can_edit?(pr, user),
         {:ok, updated} <-
           PullRequests.change_status(
             id,
             "approval-requested",
             "Thanks so much! We'll take a look and get back to you in the next week (if not sooner)",
             true
           ) do
      json(conn, %{data: JSON.pull_request_full(updated)})
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      false -> send_resp(conn, 401, "")
      {:error, :invalid_status} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_status"})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
    end
  end

  def change_status(conn, %{"id" => id, "status" => status} = params) do
    user = conn.assigns[:current_user]

    if Map.get(user, :isCommitter) == true do
      case PullRequests.change_status(id, status, params["message"], true) do
        {:ok, pr} ->
          json(conn, %{data: JSON.pull_request_full(pr)})

        # Ruby behavior: an unknown status quietly returns the unchanged PR
        # with a 200 (because `PullRequest.change_status` returns false and
        # the controller re-fetches). We do the same.
        {:error, :invalid_status} ->
          case PullRequests.get(id) do
            nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
            pr -> json(conn, %{data: JSON.pull_request_full(pr)})
          end

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Not found"})
      end
    else
      send_resp(conn, 401, "")
    end
  end

  def comment(conn, %{"id" => id, "comment" => comment}) do
    user = conn.assigns[:current_user]

    with %{} = pr <- PullRequests.get(id),
         true <- PullRequests.can_edit?(pr, user) do
      updated = PullRequests.add_comment(pr, comment, user)
      json(conn, %{data: JSON.pull_request_full(updated)})
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      false -> send_resp(conn, 401, "")
    end
  end

  defp changeset_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
