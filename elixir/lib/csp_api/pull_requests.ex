defmodule CspApi.PullRequests do
  @moduledoc "Pull-request flows. Port of `models/pull_request.rb`."

  import Ecto.Query
  alias CspApi.{Repo, ID, Email, StandardSets}
  alias CspApi.Schemas.{PullRequest, StandardSet, Activity}

  defdelegate statuses, to: PullRequest
  defdelegate humanized(status), to: PullRequest

  def get(id), do: Repo.get(PullRequest, id)

  def list_active do
    from(p in PullRequest, where: p.status != "rejected", limit: 100)
    |> Repo.all()
  end

  def list_for_user(user_id) do
    from(p in PullRequest,
      where: p.status != "rejected" and p.submitterId == ^user_id,
      select: [:id, :title, :status, :updatedAt, :createdAt]
    )
    |> Repo.all()
  end

  def can_edit?(_pr, %{isCommitter: true}), do: true
  def can_edit?(%{submitterId: sid}, %{id: uid}) when sid == uid, do: true
  def can_edit?(_pr, _user), do: false

  @doc "Create an empty PR for the current user."
  def create_blank(user) do
    name = name_of(user)
    now = now()

    activity = %{
      id: ID.csp_uuid(),
      createdAt: now,
      type: "created",
      title: "Woohoo! New pull request created by #{name}"
    }

    insert_pr(user, %{
      activities: [activity],
      standardSet: default_standard_set(),
      standardsCount: 0,
      forkedFromStandardSetId: nil,
      title: ": : ",
      createdAt: now,
      updatedAt: now,
      updatedAtDate: now
    })
  end

  @doc "Fork an existing standard set into a fresh PR."
  def create_forked(user, standard_set_id) when is_binary(standard_set_id) do
    name = name_of(user)
    now = now()

    case StandardSets.get(standard_set_id) do
      nil ->
        # Fall back to a blank PR if the source set has disappeared, matching
        # Ruby's behavior of silently degrading.
        create_blank(user)

      %StandardSet{} = source ->
        standards = source.standards || %{}

        activity = %{
          id: ID.csp_uuid(),
          createdAt: now,
          type: "forked",
          title:
            "Woohoo! New pull request created by #{name} from " <>
              "#{(source.jurisdiction && source.jurisdiction.title) || ""}: #{source.subject}: #{source.title}"
        }

        embedded_set = standard_set_for_embed(source)

        insert_pr(user, %{
          activities: [activity],
          standardSet: embedded_set,
          standardsCount: map_size(standards),
          forkedFromStandardSetId: standard_set_id,
          title: "#{(source.jurisdiction && source.jurisdiction.title) || ""}: #{source.subject}: #{source.title}",
          createdAt: now,
          updatedAt: now,
          updatedAtDate: now
        })
    end
  end

  @doc "Apply edits to the user-controlled fields of a PR."
  def user_update(id, %{} = data) do
    case Repo.get(PullRequest, id) do
      nil ->
        {:error, :not_found}

      pr ->
        standard_set = Map.get(data, "standardSet") || Map.get(data, :standardSet) || %{}
        standards = Map.get(standard_set, "standards") || Map.get(standard_set, :standards) || %{}
        jurisdiction = Map.get(standard_set, "jurisdiction") || %{}

        title =
          "#{Map.get(jurisdiction, "title", "")}: " <>
            "#{Map.get(standard_set, "subject", "")}: " <>
            "#{Map.get(standard_set, "title", "")}"

        changeset =
          PullRequest.changeset(pr, %{
            title: title,
            standardSet: standard_set,
            standardsCount: map_size(standards),
            updatedAt: now(),
            updatedAtDate: now()
          })

        case Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated}
          {:error, cs} -> {:error, cs}
        end
    end
  end

  def add_comment(pr, comment, user) when is_binary(comment) do
    activity = %Activity{
      id: ID.csp_uuid(),
      createdAt: now(),
      type: "comment",
      title: comment,
      userName: name_of(user),
      userId: user.id
    }

    activities = (pr.activities || []) ++ [activity]

    {:ok, updated} =
      pr
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_embed(:activities, activities)
      |> Repo.update()

    if Map.get(user, :isCommitter) == true do
      Email.send_email("admin-comment-added", updated, comment)
    end

    updated
  end

  @doc """
  Changes a PR's status. Returns `{:ok, pr}` or `{:error, reason}`.

  Bug-for-bug with Ruby: an unknown status returns `{:error,
  :invalid_status}` here, and the controller turns that into a 200 with
  the unchanged PR (Ruby's `change_status` returns `false`, the endpoint
  swallows it and re-fetches).
  """
  def change_status(id, status, comment, send_notice? \\ false) do
    cond do
      status not in PullRequest.statuses() ->
        {:error, :invalid_status}

      true ->
        case Repo.get(PullRequest, id) do
          nil ->
            {:error, :not_found}

          pr ->
            do_change_status(pr, status, comment, send_notice?)
        end
    end
  end

  defp do_change_status(pr, status, comment, send_notice?) do
    if status == "approved" and is_map(pr.standardSet) and pr.standardSet["id"] do
      # Ruby `change_status` calls StandardSet.update(model.standardSet)
      # which upserts using the embedded set's id. We do the same — no
      # extra validation that the id matches forkedFromStandardSetId,
      # matching Ruby.
      StandardSets.upsert(pr.standardSet)
    end

    activity = %Activity{
      id: ID.csp_uuid(),
      createdAt: now(),
      type: "status-change",
      status: PullRequest.humanized(status),
      title: comment || ""
    }

    activities = (pr.activities || []) ++ [activity]

    {:ok, updated} =
      pr
      |> Ecto.Changeset.change(%{
        status: status,
        statusComment: comment,
        updatedAtDate: now()
      })
      |> Ecto.Changeset.put_embed(:activities, activities)
      |> Repo.update()

    if send_notice?, do: Email.send_email(status, updated, comment)

    {:ok, updated}
  end

  # ────────────────────────────────────────────────────────────────────────

  defp insert_pr(user, fields) do
    id = ID.csp_uuid()

    attrs =
      Map.merge(fields, %{
        id: id,
        submitterId: user.id,
        submitterEmail: Map.get(user, :email, "noemail@example.com"),
        submitterName: name_of(user),
        status: "draft",
        pullRequestUrl: "https://commonstandardsproject.com/edit/pull-requests/" <> id
      })

    %PullRequest{}
    |> PullRequest.changeset(attrs)
    |> Repo.insert!()
  end

  defp default_standard_set do
    %{
      "id" => ID.csp_uuid(),
      "title" => "",
      "subject" => "",
      "document" => %{},
      "standards" => %{},
      "educationLevels" => [],
      "license" => %{
        "title" => "CC BY 4.0 US",
        "URL" => "http://creativecommons.org/licenses/by/4.0/us/",
        "rightsHolder" => "Common Curriculum, Inc."
      },
      "jurisdiction" => %{"id" => "", "title" => ""},
      "cspStatus" => %{"value" => "visible"}
    }
  end

  defp standard_set_for_embed(%StandardSet{} = s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "subject" => s.subject,
      "normalizedSubject" => s.normalizedSubject,
      "educationLevels" => s.educationLevels,
      "standards" => s.standards,
      "document" => s.document && Map.from_struct(s.document),
      "jurisdiction" => s.jurisdiction && Map.from_struct(s.jurisdiction),
      "cspStatus" => s.cspStatus && Map.from_struct(s.cspStatus),
      "license" => s.license && Map.from_struct(s.license)
    }
  end

  defp name_of(user) do
    cond do
      profile = Map.get(user, :profile) ->
        Map.get(profile, "name") || Map.get(profile, :name) || "anonymous"

      true ->
        "anonymous"
    end
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
