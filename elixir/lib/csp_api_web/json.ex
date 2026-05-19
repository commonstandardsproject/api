defmodule CspApiWeb.JSON do
  @moduledoc """
  Response shapers — equivalent to the Grape entities in `api/entities/`.

  One module covers every resource type because the shapes are small and
  the cross-references (PR → standardSet → activities → jurisdiction) all
  live in one file rather than chained across five.
  """

  alias CspApi.Schemas.{Jurisdiction, StandardSet, User, PullRequest, Activity}

  # ── Jurisdictions ──────────────────────────────────────────────────────

  def jurisdiction_summary(%Jurisdiction{} = j) do
    %{"id" => j.id, "title" => j.title, "type" => j.type}
  end

  def jurisdiction_summary(j) when is_map(j) do
    %{"id" => j["_id"] || j["id"], "title" => j["title"], "type" => j["type"]}
  end

  def jurisdiction_full(%Jurisdiction{} = j, standard_sets) do
    %{
      "id" => j.id,
      "title" => j.title,
      "type" => j.type,
      "standardSets" => Enum.map(standard_sets || [], &standard_set_summary/1)
    }
  end

  # ── Standard sets ──────────────────────────────────────────────────────

  def standard_set_summary(%StandardSet{} = s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "subject" => s.subject,
      "educationLevels" => s.educationLevels || [],
      "document" => s.document || %{}
    }
  end

  def standard_set_summary(s) when is_map(s) do
    %{
      "id" => s["_id"] || s["id"],
      "title" => s["title"],
      "subject" => s["subject"],
      "educationLevels" => s["educationLevels"] || [],
      "document" => s["document"] || %{}
    }
  end

  def standard_set_full(%StandardSet{} = s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "subject" => s.subject,
      "normalizedSubject" => s.normalizedSubject,
      "educationLevels" => s.educationLevels || [],
      "cspStatus" => embedded(s.cspStatus),
      "license" => embedded(s.license),
      "document" => s.document || %{},
      "jurisdiction" => embedded(s.jurisdiction),
      "standards" => s.standards
    }
  end

  # When change_status approves a PR with a raw map standardSet, we need to
  # render it back out without a full schema cast.
  def standard_set_full(s) when is_map(s) do
    %{
      "id" => s["_id"] || s["id"],
      "title" => s["title"],
      "subject" => s["subject"],
      "normalizedSubject" => s["normalizedSubject"],
      "educationLevels" => s["educationLevels"] || [],
      "cspStatus" => s["cspStatus"] || %{},
      "license" => s["license"] || %{},
      "document" => s["document"] || %{},
      "jurisdiction" => s["jurisdiction"] || %{},
      "standards" => s["standards"] || %{}
    }
  end

  # ── Users ──────────────────────────────────────────────────────────────

  def user(%User{} = u) do
    %{
      "id" => u.id,
      "profile" => u.profile,
      "email" => u.email,
      "apiKey" => u.apiKey,
      "algoliaApiKey" => u.algoliaApiKey,
      "allowedOrigins" => u.allowedOrigins || [],
      "pullRequests" => Map.get(u, :pullRequests, []),
      "isCommitter" => u.isCommitter
    }
  end

  # ── Pull requests ──────────────────────────────────────────────────────

  def pull_request_full(%PullRequest{} = pr) do
    %{
      "id" => pr.id,
      "createdAt" => pr.createdAt,
      "updatedAt" => pr.updatedAt,
      "title" => pr.title,
      "submitterId" => pr.submitterId,
      "submitterEmail" => pr.submitterEmail,
      "submitterName" => pr.submitterName,
      "activities" => Enum.map(pr.activities || [], &activity/1),
      "forkedFromStandardSetId" => pr.forkedFromStandardSetId,
      "statusComment" => pr.statusComment,
      "standardSet" => standard_set_full(pr.standardSet || %{}),
      "status" => pr.status
    }
  end

  def pull_request_summary(pr) do
    pr = if is_struct(pr), do: Map.from_struct(pr), else: pr

    %{
      "id" => pr[:id] || pr["id"] || pr["_id"],
      "createdAt" => pr[:createdAt] || pr["createdAt"],
      "updatedAt" => pr[:updatedAt] || pr["updatedAt"],
      "title" => pr[:title] || pr["title"],
      "status" => pr[:status] || pr["status"]
    }
  end

  def activity(%Activity{} = a) do
    %{
      "id" => a.id,
      "createdAt" => a.createdAt,
      "type" => a.type,
      "status" => a.status,
      "title" => a.title,
      "userId" => a.userId,
      "userName" => a.userName
    }
  end

  def activity(a) when is_map(a) do
    %{
      "id" => a["id"],
      "createdAt" => a["createdAt"],
      "type" => a["type"],
      "status" => a["status"],
      "title" => a["title"],
      "userId" => a["userId"],
      "userName" => a["userName"]
    }
  end

  defp embedded(nil), do: %{}
  defp embedded(%_{} = struct), do: Map.from_struct(struct)
  defp embedded(map) when is_map(map), do: map
end
