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
          MongoX.find("standard_sets", filter, projection: @summary_projection)

        {jurisdiction, sets}
    end
  end
end
