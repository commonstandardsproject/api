defmodule CspApi.Schemas.PullRequest do
  @moduledoc "Port of `models/pull_request.rb`."

  use Ecto.Schema
  import Ecto.Changeset

  alias CspApi.Schemas.Activity

  @statuses ["draft", "approval-requested", "revise-and-resubmit", "approved", "rejected"]

  @humanized %{
    "draft" => "Draft",
    "approval-requested" => "Approval Requested",
    "revise-and-resubmit" => "Revise and Resubmit",
    "approved" => "Approved",
    "rejected" => "Rejected"
  }

  def statuses, do: @statuses
  def humanized(status), do: Map.get(@humanized, status, status)

  @primary_key {:id, :string, autogenerate: false}

  schema "pull_requests" do
    field :submitterId, :string
    field :submitterEmail, :string, default: "noemail@example.com"
    field :submitterName, :string
    field :status, :string, default: "draft"
    field :statusComment, :string
    field :forkedFromStandardSetId, :string
    field :standardsCount, :integer, default: 0
    field :asanaTaskId, :string
    field :createdAt, :utc_datetime
    field :updatedAt, :utc_datetime
    field :updatedAtDate, :utc_datetime
    field :pullRequestUrl, :string
    field :title, :string

    # Stored as a raw map to match the existing Mongo documents — the
    # embedded standardSet doesn't always conform to the full StandardSet
    # schema in production data.
    field :standardSet, :map, default: %{}

    embeds_many :activities, Activity, on_replace: :delete
  end

  @cast_fields ~w(
    id submitterId submitterEmail submitterName status statusComment
    forkedFromStandardSetId standardsCount asanaTaskId
    createdAt updatedAt updatedAtDate pullRequestUrl title standardSet
  )a

  def changeset(pr, attrs) do
    pr
    |> cast(attrs, @cast_fields)
    |> cast_embed(:activities)
    |> validate_required([:submitterId, :submitterName, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
