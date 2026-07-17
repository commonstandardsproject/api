defmodule CspApi.Jurisdictions do
  @moduledoc "Read operations for `jurisdictions`, plus the joined standard-set summary."

  import Ecto.Query
  alias CspApi.Repo
  alias CspApi.Schemas.{Jurisdiction, StandardSet}

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
    # Stringify atom keys so the merge below doesn't produce a mixed-key
    # map (Ecto.Changeset.cast rejects those). String keys are GC-safe;
    # avoid `String.to_atom` on user input.
    attrs =
      attrs
      |> stringify_keys()
      |> Map.put("status", "pending")
      |> Map.put("submitterId", submitter_id)
      |> Map.put_new("id", CspApi.ID.csp_uuid())

    %Jurisdiction{}
    |> Jurisdiction.changeset(attrs)
    |> Repo.insert()
  end

  defp stringify_keys(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      kv -> kv
    end)
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
        # mongodb_ecto doesn't expose embed-field navigation through Ecto's
        # standard DSL (`s.jurisdiction.id` raises in query compilation), so
        # we pass nested filters through `fragment/1` — the adapter encodes
        # the keyword list as a Mongo find filter verbatim.
        sets =
          StandardSet
          |> where_jurisdiction(id)
          |> maybe_hide_hidden(hide_hidden?)
          |> select([s], map(s, [:id, :title, :subject, :document, :educationLevels]))
          |> Repo.all()

        {jurisdiction, sets}
    end
  end

  defp where_jurisdiction(query, jurisdiction_id) do
    from s in query, where: fragment("jurisdiction.id": ^jurisdiction_id)
  end

  defp maybe_hide_hidden(query, false), do: query

  defp maybe_hide_hidden(query, true) do
    # Mongo's `$ne` is true for "not equal" and for "field missing", which
    # is what we want — hide only docs where cspStatus.value is exactly
    # "hidden".
    from s in query, where: fragment("cspStatus.value": ["$ne": "hidden"])
  end
end
