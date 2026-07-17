defmodule CspApiWeb.PullRequests.ActivityJSON do
  @moduledoc "Embedded inside a PR's `activities` list."
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :createdAt, :string
    field :type, :string
    field :status, :string
    field :title, :string
    field :userId, :string
    field :userName, :string
  end
end

defmodule CspApiWeb.PullRequests.DetailJSON do
  @moduledoc "Full PR response — for show/create/update/submit/comment/change_status."
  use Ecto.Schema
  use CspApiWeb.View

  alias CspApiWeb.PullRequests.ActivityJSON
  alias CspApiWeb.StandardSets.DetailJSON, as: StandardSetDetail

  embedded_schema do
    field :createdAt, :string
    field :updatedAt, :string
    field :title, :string
    field :submitterId, :string
    field :submitterEmail, :string
    field :submitterName, :string
    embeds_many :activities, ActivityJSON
    field :forkedFromStandardSetId, :string
    field :statusComment, :string
    embeds_one :standardSet, StandardSetDetail
    field :status, :string
  end
end

defmodule CspApiWeb.PullRequests.SummaryJSON do
  @moduledoc "Shape for entries in `GET /api/v1/pull_requests/user/:user_id`."
  use Ecto.Schema
  use CspApiWeb.View

  embedded_schema do
    field :createdAt, :string
    field :updatedAt, :string
    field :title, :string
    field :status, :string
  end
end
