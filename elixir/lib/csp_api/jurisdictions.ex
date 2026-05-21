defmodule CspApi.Jurisdictions do
  @moduledoc "Read operations for `jurisdictions`, plus the joined standard-set summary."

  import Ecto.Query
  alias CspApi.{Repo, MongoX}
  alias CspApi.Schemas.Jurisdiction

  @summary_projection %{
    "_id" => 1,
    "title" => 1,
    "subject" => 1,
    "document" => 1,
    "educationLevels" => 1
  }

  @doc """
  Lists jurisdictions for the public listing — hides inactive/pending/rejected
  unless the requester submitted them. Mirrors the `:$or` query in
  `api/jurisdictions.rb`.
  """
  def list_all(user_id \\ nil) do
    query =
      case user_id do
        nil ->
          from j in Jurisdiction,
            where: j.status not in ["inactive", "pending", "rejected"] or is_nil(j.status),
            order_by: [asc: j.title]

        id ->
          from j in Jurisdiction,
            where:
              (j.status not in ["inactive", "pending", "rejected"] or is_nil(j.status)) or
                j.submitterId == ^id,
            order_by: [asc: j.title]
      end

    Repo.all(query)
  end

  @doc """
  Creates a new jurisdiction in `pending` status. Mirrors the hidden
  `POST /jurisdictions` endpoint in `api/jurisdictions.rb`.
  """
  def create_pending(attrs, submitter_id) do
    attrs =
      attrs
      |> Map.put(:status, "pending")
      |> Map.put(:submitterId, submitter_id)
      |> Map.put_new(:id, CspApi.ID.csp_uuid())

    %Jurisdiction{}
    |> Jurisdiction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Flips a jurisdiction from `pending` (or any other status) to
  `approved`. Called from the PR-approval flow — matches
  `models/jurisdiction.rb:30` `Jurisdiction.approve`.
  """
  def approve(id) when is_binary(id) do
    case Repo.get(Jurisdiction, id) do
      nil ->
        :not_found

      j ->
        j
        |> Ecto.Changeset.change(status: "approved")
        |> Repo.update!()
        :ok
    end
  end

  def approve(_), do: :not_found

  @doc """
  Fetches a jurisdiction and joins on the standard-set summary collection.
  `hide_hidden_sets?` defaults to true, matching the Ruby endpoint.

  Returns `{jurisdiction, [standard_set_summary_map]}` or `nil`.
  """
  def get(id, opts \\ []) do
    hide_hidden? = Keyword.get(opts, :hide_hidden_sets, true)

    case Repo.get(Jurisdiction, id) do
      nil ->
        nil

      jurisdiction ->
        filter = %{"jurisdiction.id" => id}

        filter =
          if hide_hidden? do
            Map.put(filter, "cspStatus.value", %{"$ne" => "hidden"})
          else
            filter
          end

        sets =
          "standard_sets"
          |> MongoX.find(filter, projection: @summary_projection)
          |> Enum.map(&MongoX.normalize_id/1)

        {jurisdiction, sets}
    end
  end
end
