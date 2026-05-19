defmodule CspApiWeb.PullRequestJSON do
  @moduledoc "Port of `api/entities/pull_request.rb` and `pull_request_summary.rb`."

  alias CspApi.Schemas.PullRequest
  alias CspApiWeb.{StandardSetJSON, ActivityJSON}

  def full(%PullRequest{} = pr) do
    %{
      "id" => pr.id,
      "createdAt" => pr.createdAt,
      "updatedAt" => pr.updatedAt,
      "title" => pr.title,
      "submitterId" => pr.submitterId,
      "submitterEmail" => pr.submitterEmail,
      "submitterName" => pr.submitterName,
      "activities" => Enum.map(pr.activities || [], &ActivityJSON.show/1),
      "forkedFromStandardSetId" => pr.forkedFromStandardSetId,
      "statusComment" => pr.statusComment,
      "standardSet" => StandardSetJSON.full(pr.standardSet || %{}),
      "status" => pr.status
    }
  end

  def summary(pr) do
    pr = if is_struct(pr), do: Map.from_struct(pr), else: pr

    %{
      "id" => pr[:id] || pr["id"] || pr["_id"],
      "createdAt" => pr[:createdAt] || pr["createdAt"],
      "updatedAt" => pr[:updatedAt] || pr["updatedAt"],
      "title" => pr[:title] || pr["title"],
      "status" => pr[:status] || pr["status"]
    }
  end
end
