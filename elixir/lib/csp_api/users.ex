defmodule CspApi.Users do
  @moduledoc "User upsert and lookup. Port of `models/user.rb`."

  alias CspApi.{Repo, ID}
  alias CspApi.Schemas.User

  @doc """
  Returns the user whose `apiKey` matches the given key, *and* increments
  their `requestCount`. Used by the auth plug.

  Matches the Ruby behavior bug-for-bug: a `nil` key still hits Mongo
  with `{apiKey: nil}`, which can match a user document that has no
  `apiKey` field. See `CspApiWeb.Plugs.ApiKeyAuth` for context.
  """
  def by_api_key_and_bump(key) do
    # We use a raw $inc through the adapter so the request count is
    # incremented atomically alongside the find. Ecto's `Repo.update` would
    # require a fetch-then-update, which is racier and exactly what the
    # Ruby code avoids.
    case Mongo.Ecto.command(Repo,
           findAndModify: "users",
           query: %{"apiKey" => key},
           update: %{"$inc" => %{"requestCount" => 1}},
           new: true
         ) do
      %{"value" => nil} -> nil
      %{"value" => doc} -> load_user(doc)
      _ -> nil
    end
  end

  def by_id(nil), do: nil
  def by_id(id), do: Repo.get(User, id)

  def by_email(nil), do: nil
  def by_email(email), do: Repo.get_by(User, email: email)

  @doc """
  Idempotent sign-in. Upserts on email, sets `_id`/`allowedOrigins` on
  insert, increments `signInCount`, generates an `apiKey` if missing.

  Returns the updated user.
  """
  def upsert_signed_in(%{} = profile_outer) do
    profile = profile_outer["profile"] || profile_outer[:profile] || %{}
    email = profile["email"] || profile[:email]

    new_id = ID.csp_uuid()

    %{"value" => upserted} =
      Mongo.Ecto.command(Repo,
        findAndModify: "users",
        query: %{"email" => email},
        update: %{
          "$inc" => %{"signInCount" => 1},
          "$set" => %{
            "email" => email,
            "profile" => profile
          },
          "$setOnInsert" => %{
            "_id" => new_id,
            "allowedOrigins" => []
          }
        },
        upsert: true,
        new: true
      )

    if upserted["apiKey"] in [nil, ""] do
      %{"value" => with_key} =
        Mongo.Ecto.command(Repo,
          findAndModify: "users",
          query: %{"_id" => upserted["_id"]},
          update: %{"$set" => %{"apiKey" => ID.base58(24)}},
          new: true
        )

      load_user(with_key)
    else
      load_user(upserted)
    end
  end

  def set_allowed_origins(id, origins) when is_list(origins) do
    case Repo.get(User, id) do
      nil ->
        nil

      user ->
        user
        |> Ecto.Changeset.change(allowedOrigins: origins)
        |> Repo.update!()
    end
  end

  @doc "Test helper — creates a user with the given attrs verbatim."
  def create(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> stringify_keys()
      |> Map.put_new("_id", attrs["id"] || attrs[:id] || ID.csp_uuid())
      |> Map.put_new("apiKey", ID.base58(24))

    Mongo.Ecto.command(Repo, insert: "users", documents: [attrs])
    Repo.get(User, attrs["_id"])
  end

  defp load_user(doc) when is_map(doc) do
    attrs = %{
      id: doc["_id"],
      email: doc["email"],
      apiKey: doc["apiKey"],
      algoliaApiKey: doc["algoliaApiKey"],
      profile: doc["profile"] || %{},
      allowedOrigins: doc["allowedOrigins"] || [],
      isCommitter: doc["isCommitter"] || false,
      requestCount: doc["requestCount"] || 0,
      signInCount: doc["signInCount"] || 0
    }

    struct(User, attrs)
  end

  defp stringify_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      kv -> kv
    end)
  end
end
