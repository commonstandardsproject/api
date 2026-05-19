defmodule CspApiWeb.PullRequestJSON do
  @moduledoc "Mirrors `api/entities/pull_request.rb` and `pull_request_summary.rb`."

  alias CspApiWeb.{StandardSetJSON, ActivityJSON}

  def full(pr) do
    %{
      "id" => pr["_id"] || pr["id"],
      "createdAt" => pr["createdAt"],
      "updatedAt" => pr["updatedAt"],
      "title" => pr["title"],
      "submitterId" => pr["submitterId"],
      "submitterEmail" => pr["submitterEmail"],
      "submitterName" => pr["submitterName"],
      "activities" => Enum.map(pr["activities"] || [], &ActivityJSON.full/1),
      "forkedFromStandardSetId" => pr["forkedFromStandardSetId"],
      "statusComment" => pr["statusComment"],
      "standardSet" => StandardSetJSON.full(pr["standardSet"] || %{}),
      "status" => pr["status"]
    }
  end

  def summary(pr) do
    %{
      "id" => pr["_id"] || pr["id"],
      "createdAt" => pr["createdAt"],
      "updatedAt" => pr["updatedAt"],
      "title" => pr["title"],
      "status" => pr["status"]
    }
  end
end
