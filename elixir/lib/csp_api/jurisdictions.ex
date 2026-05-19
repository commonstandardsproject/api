defmodule CspApi.Jurisdictions do
  @moduledoc """
  Read operations for the `jurisdictions` collection plus the joined
  `standardSets` summary used by `GET /api/v1/jurisdictions/:id`.
  """

  alias CspApi.Mongo

  @summary_projection %{
    "_id" => 1,
    "title" => 1,
    "subject" => 1,
    "document" => 1,
    "educationLevels" => 1
  }

  @doc """
  Lists all jurisdictions that the public should see.

  The Ruby app filters out items with `status in [inactive, pending,
  rejected]` *unless* the requester submitted them. Without an authenticated
  user we just hide all three.
  """
  def list_all(user_id \\ nil) do
    status_filter = %{"status" => %{"$nin" => ["inactive", "pending", "rejected"]}}

    filter =
      case user_id do
        nil -> status_filter
        id -> %{"$or" => [status_filter, %{"submitterId" => id}]}
      end

    Mongo.find_all("jurisdictions", filter, sort: %{"title" => 1})
  end

  @doc """
  Fetches a jurisdiction and attaches its standard-set summary list. When
  `hide_hidden_sets?` is true (the default), sets whose `cspStatus.value`
  equals `"hidden"` are filtered out.
  """
  def get(id, opts \\ []) do
    hide_hidden? = Keyword.get(opts, :hide_hidden_sets, true)

    case Mongo.find_one("jurisdictions", %{"_id" => id}) do
      nil ->
        nil

      jurisdiction ->
        set_filter = %{"jurisdiction.id" => id}

        set_filter =
          if hide_hidden? do
            Map.put(set_filter, "cspStatus.value", %{"$ne" => "hidden"})
          else
            set_filter
          end

        standard_sets = Mongo.find_all("standard_sets", set_filter, projection: @summary_projection)
        Map.put(jurisdiction, "standardSets", standard_sets)
    end
  end
end
