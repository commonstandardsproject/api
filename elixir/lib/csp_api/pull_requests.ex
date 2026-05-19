defmodule CspApi.PullRequests do
  @moduledoc """
  Pull requests carry user-proposed edits to a `StandardSet`. Port of
  `models/pull_request.rb`.
  """

  alias CspApi.{Mongo, ID, Email, StandardSets}

  @statuses ["draft", "approval-requested", "revise-and-resubmit", "approved", "rejected"]
  @humanized_statuses %{
    "draft" => "Draft",
    "approval-requested" => "Approval Requested",
    "revise-and-resubmit" => "Revise and Resubmit",
    "approved" => "Approved",
    "rejected" => "Rejected"
  }

  def statuses, do: @statuses

  def get(id), do: Mongo.find_one("pull_requests", %{"_id" => id})

  def list_active do
    "pull_requests"
    |> Mongo.find_all(%{"status" => %{"$ne" => "rejected"}}, limit: 100)
  end

  def list_for_user(user_id) do
    Mongo.find_all(
      "pull_requests",
      %{"status" => %{"$ne" => "rejected"}, "submitterId" => user_id},
      projection: %{"title" => 1, "status" => 1, "updatedAt" => 1, "createdAt" => 1}
    )
  end

  def can_edit?(_pr, %{"isCommitter" => true}), do: true
  def can_edit?(%{"submitterId" => sid}, %{"_id" => uid}) when sid == uid, do: true
  def can_edit?(%{"submitterId" => sid}, %{"id" => uid}) when sid == uid, do: true
  def can_edit?(_pr, _user), do: false

  @doc """
  Creates a new pull request, optionally forked from an existing standard
  set.
  """
  def create(user, standard_set_id \\ nil) do
    id = ID.csp_uuid()
    name = get_in(user, ["profile", "name"]) || "anonymous"

    {standard_set, forked_from, activity, count} =
      if is_binary(standard_set_id) and standard_set_id != "" do
        ss = StandardSets.get(standard_set_id)

        title =
          "Woohoo! New pull request created by #{name} from " <>
            (get_in(ss || %{}, ["jurisdiction", "title"]) || "") <>
            ": " <>
            (Map.get(ss || %{}, "subject", "")) <>
            ": " <>
            (Map.get(ss || %{}, "title", ""))

        {ss, standard_set_id, %{"type" => "forked", "title" => title}, map_size(ss["standards"] || %{})}
      else
        {default_standard_set(), nil,
         %{"type" => "created", "title" => "Woohoo! New pull request created by #{name}"}, 0}
      end

    now = DateTime.utc_now()

    activity =
      activity
      |> Map.put("id", ID.csp_uuid())
      |> Map.put("createdAt", now)

    doc = %{
      "_id" => id,
      "submitterId" => user["_id"] || user["id"],
      "submitterEmail" => Map.get(user, "email", "noemail@example.com"),
      "submitterName" => name,
      "status" => "draft",
      "activities" => [activity],
      "standardSet" => standard_set,
      "forkedFromStandardSetId" => forked_from,
      "standardsCount" => count,
      "createdAt" => now,
      "updatedAt" => now,
      "updatedAtDate" => now,
      "pullRequestUrl" => "https://commonstandardsproject.com/edit/pull-requests/" <> id,
      "title" => "#{get_in(standard_set, ["jurisdiction", "title"]) || ""}: #{Map.get(standard_set, "subject", "")}: #{Map.get(standard_set, "title", "")}"
    }

    Mongo.insert_one("pull_requests", doc)
    doc
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

  @doc """
  Updates the user-editable part of a pull request: title and the embedded
  `standardSet`.
  """
  def user_update(id, %{} = data) do
    standard_set = Map.get(data, "standardSet") || %{}
    standards = Map.get(standard_set, "standards") || %{}
    jurisdiction = Map.get(standard_set, "jurisdiction", %{})

    title =
      "#{Map.get(jurisdiction, "title", "")}: " <>
        "#{Map.get(standard_set, "subject", "")}: " <>
        "#{Map.get(standard_set, "title", "")}"

    updates = %{
      "title" => title,
      "standardSet" => standard_set,
      "standardsCount" => map_size(standards),
      "updatedAt" => DateTime.utc_now(),
      "updatedAtDate" => DateTime.utc_now()
    }

    {:ok, model} =
      Mongo.find_one_and_update(
        "pull_requests",
        %{"_id" => id},
        %{"$set" => updates},
        return_document: :after
      )

    {:ok, model}
  end

  def add_comment(pr, comment, user) when is_map(pr) and is_binary(comment) do
    activity = %{
      "id" => ID.csp_uuid(),
      "createdAt" => DateTime.utc_now(),
      "type" => "comment",
      "title" => comment,
      "userName" => get_in(user, ["profile", "name"]),
      "userId" => user["_id"] || user["id"]
    }

    Mongo.update_one(
      "pull_requests",
      %{"_id" => pr["_id"]},
      %{"$push" => %{"activities" => activity}}
    )

    if user["isCommitter"] == true do
      Email.send_email("admin-comment-added", pr, comment)
    end

    get(pr["_id"])
  end

  @doc """
  Changes the status, appends an activity, and (when `send_notice?` is
  true) sends the status-change email. Returns the updated PR or
  `{:error, :invalid_status}` if the status is unknown.
  """
  def change_status(id, status, comment, send_notice? \\ false)

  def change_status(_id, status, _comment, _send) when status not in @statuses,
    do: {:error, :invalid_status}

  def change_status(id, status, comment, send_notice?) do
    pr = get(id)
    if is_nil(pr), do: throw({:no_pr, id})

    if status == "approved" do
      StandardSets.upsert(Map.merge(pr["standardSet"], %{"id" => get_in(pr, ["standardSet", "id"])}))
    end

    {:ok, updated} =
      Mongo.find_one_and_update(
        "pull_requests",
        %{"_id" => id},
        %{
          "$set" => %{
            "status" => status,
            "statusComment" => comment,
            "updatedAtDate" => DateTime.utc_now()
          }
        },
        return_document: :after
      )

    activity = %{
      "id" => ID.csp_uuid(),
      "createdAt" => DateTime.utc_now(),
      "type" => "status-change",
      "status" => @humanized_statuses[status],
      "title" => comment || ""
    }

    Mongo.update_one(
      "pull_requests",
      %{"_id" => id},
      %{"$push" => %{"activities" => activity}}
    )

    if send_notice?, do: Email.send_email(status, updated, comment)

    get(id)
  end
end
