defmodule CspApi.Users do
  @moduledoc """
  User CRUD plus the sign-in upsert that the frontend hits after Auth0.
  """

  alias CspApi.{Mongo, ID}

  @doc "Returns the user matching the api key, or nil."
  def by_api_key(nil), do: nil

  def by_api_key(key) do
    Mongo.find_one_and_update(
      "users",
      %{"apiKey" => key},
      %{"$inc" => %{"requestCount" => 1}}
    )
    |> case do
      {:ok, user} -> user
      user when is_map(user) -> user
      _ -> nil
    end
  end

  def by_id(nil), do: nil
  def by_id(id), do: Mongo.find_one("users", %{"_id" => id})

  def by_email(nil), do: nil
  def by_email(email), do: Mongo.find_one("users", %{"email" => email})

  @doc """
  Idempotent "sign in" creating the user on first call. Matches the
  semantics of the Ruby `POST /users/signed_in`.
  """
  def upsert_signed_in(%{} = profile) do
    email = profile["email"] || profile[:email]
    name = profile["name"] || profile[:name]
    new_id = ID.csp_uuid()

    {:ok, user} =
      Mongo.find_one_and_update(
        "users",
        %{"email" => email},
        %{
          "$inc" => %{"signInCount" => 1},
          "$set" => %{"profile" => %{"email" => email, "name" => name}, "email" => email},
          "$setOnInsert" => %{"_id" => new_id, "allowedOrigins" => []}
        },
        upsert: true,
        return_document: :after
      )

    if Map.get(user, "apiKey") in [nil, ""] do
      {:ok, user} =
        Mongo.find_one_and_update(
          "users",
          %{"_id" => user["_id"]},
          %{"$set" => %{"apiKey" => ID.base58(24)}},
          return_document: :after
        )

      user
    else
      user
    end
  end

  def set_allowed_origins(id, origins) when is_list(origins) do
    {:ok, user} =
      Mongo.find_one_and_update(
        "users",
        %{"_id" => id},
        %{"$set" => %{"allowedOrigins" => origins}},
        return_document: :after
      )

    user
  end

  @doc "Used in tests and the importer to bootstrap a known user."
  def create(attrs) do
    attrs =
      attrs
      |> Map.put_new("_id", attrs["id"] || ID.csp_uuid())
      |> Map.put_new("apiKey", ID.base58(24))
      |> Map.delete("id")

    Mongo.insert_one("users", attrs)
    attrs
  end
end
