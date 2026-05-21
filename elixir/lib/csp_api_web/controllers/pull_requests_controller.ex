defmodule CspApiWeb.PullRequestsController do
  use CspApiWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias CspApi.PullRequests
  alias CspApiWeb.Errors
  alias CspApiWeb.PullRequests.{DetailJSON, SummaryJSON}

  tags ["PullRequests"]

  operation :index,
    summary: "List all active pull requests",
    responses: [
      ok: {"All non-rejected pull requests, full detail", "application/json", DetailJSON.list_schema()}
    ]

  def index(conn, _params) do
    prs = PullRequests.list_active()
    json(conn, %{data: Enum.map(prs, &DetailJSON.data/1)})
  end

  operation :for_user,
    summary: "List a user's open pull requests",
    parameters: [user_id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"The requested user's open pull requests (summary fields)", "application/json", SummaryJSON.list_schema()}
    ]

  def for_user(conn, %{"user_id" => user_id}) do
    prs = PullRequests.list_for_user(user_id)
    json(conn, %{data: Enum.map(prs, &SummaryJSON.data/1)})
  end

  operation :show,
    summary: "Fetch a pull request by id",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"The requested pull request with full detail", "application/json", DetailJSON.schema()},
      not_found: {"Pull request not found", "application/json", Errors.JSON.schema()}
    ]

  def show(conn, %{"id" => id}) do
    case PullRequests.get(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      pr -> json(conn, %{data: DetailJSON.data(pr)})
    end
  end

  operation :create,
    summary: "Open a new pull request",
    description: "If `standardSetId` is provided, the PR forks that set; otherwise it starts blank.",
    request_body:
      {"PR seed", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{standardSetId: %OpenApiSpex.Schema{type: :string}}
       }},
    responses: [
      ok: {"The newly created pull request", "application/json", DetailJSON.schema()}
    ]

  def create(conn, params) do
    user = conn.assigns[:current_user]
    standard_set_id = params["standardSetId"] || params["standard_set_id"]

    pr =
      if is_binary(standard_set_id) and standard_set_id != "" do
        PullRequests.create_forked(user, standard_set_id)
      else
        PullRequests.create_blank(user)
      end

    json(conn, %{data: DetailJSON.data(pr)})
  end

  operation :user_update,
    summary: "Update the PR's draft contents",
    parameters: [id: [in: :path, required: true, type: :string]],
    request_body:
      {"PR data", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{data: %OpenApiSpex.Schema{type: :object, additionalProperties: true}}
       }},
    responses: [
      ok: {"The pull request with the requested changes applied", "application/json", DetailJSON.schema()},
      not_found: {"Pull request not found", "application/json", Errors.JSON.schema()},
      unprocessable_entity: {"Validation errors", "application/json", Errors.JSON.schema()},
      unauthorized: {"Caller cannot edit this PR", "application/json", Errors.JSON.schema()}
    ]

  def user_update(conn, %{"id" => id} = params) do
    user = conn.assigns[:current_user]

    with %{} = pr <- PullRequests.get(id),
         true <- PullRequests.can_edit?(pr, user) do
      case PullRequests.user_update(id, params["data"] || %{}) do
        {:ok, updated} ->
          json(conn, %{data: DetailJSON.data(updated)})

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

  operation :submit,
    summary: "Submit the PR for review",
    parameters: [id: [in: :path, required: true, type: :string]],
    responses: [
      ok: {"The pull request, now in `approval-requested` status", "application/json", DetailJSON.schema()},
      not_found: {"Pull request not found", "application/json", Errors.JSON.schema()},
      unauthorized: {"Caller cannot edit this PR", "application/json", Errors.JSON.schema()}
    ]

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
      json(conn, %{data: DetailJSON.data(updated)})
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      false -> send_resp(conn, 401, "")
      {:error, :invalid_status} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_status"})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
    end
  end

  operation :change_status,
    summary: "Committer-only: change a PR's status",
    description: "Valid values: `approved`, `rejected`, `revise-and-resubmit`. Any other value silently keeps the PR as `draft` (bug-compatible with Ruby).",
    parameters: [id: [in: :path, required: true, type: :string]],
    request_body:
      {"Status + optional message", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{
           status: %OpenApiSpex.Schema{type: :string},
           message: %OpenApiSpex.Schema{type: :string}
         },
         required: [:status]
       }},
    responses: [
      ok: {"The pull request, possibly with a new status", "application/json", DetailJSON.schema()},
      not_found: {"Pull request not found", "application/json", Errors.JSON.schema()},
      unauthorized: {"Caller is not a committer", "application/json", Errors.JSON.schema()}
    ]

  def change_status(conn, %{"id" => id, "status" => status} = params) do
    user = conn.assigns[:current_user]

    if Map.get(user, :isCommitter) == true do
      case PullRequests.change_status(id, status, params["message"], true) do
        {:ok, pr} ->
          json(conn, %{data: DetailJSON.data(pr)})

        # Ruby returns the unchanged PR with 200 when status is unknown.
        {:error, :invalid_status} ->
          case PullRequests.get(id) do
            nil -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
            pr -> json(conn, %{data: DetailJSON.data(pr)})
          end

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Not found"})
      end
    else
      send_resp(conn, 401, "")
    end
  end

  operation :comment,
    summary: "Add a comment to a PR",
    parameters: [id: [in: :path, required: true, type: :string]],
    request_body:
      {"Comment body", "application/json",
       %OpenApiSpex.Schema{
         type: :object,
         properties: %{comment: %OpenApiSpex.Schema{type: :string}},
         required: [:comment]
       }},
    responses: [
      ok: {"The pull request with the new comment appended to its activities", "application/json", DetailJSON.schema()},
      not_found: {"Pull request not found", "application/json", Errors.JSON.schema()},
      unauthorized: {"Caller cannot edit this PR", "application/json", Errors.JSON.schema()}
    ]

  def comment(conn, %{"id" => id, "comment" => comment}) do
    user = conn.assigns[:current_user]

    with %{} = pr <- PullRequests.get(id),
         true <- PullRequests.can_edit?(pr, user) do
      updated = PullRequests.add_comment(pr, comment, user)
      json(conn, %{data: DetailJSON.data(updated)})
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
