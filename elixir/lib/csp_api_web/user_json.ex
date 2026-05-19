defmodule CspApiWeb.UserJSON do
  @moduledoc "Port of `api/entities/user.rb`."

  alias CspApi.Schemas.User

  def show(%User{} = u) do
    %{
      "id" => u.id,
      "profile" => u.profile,
      "email" => u.email,
      "apiKey" => u.apiKey,
      "algoliaApiKey" => u.algoliaApiKey,
      "allowedOrigins" => u.allowedOrigins || [],
      "pullRequests" => Map.get(u, :pullRequests, []),
      "isCommitter" => u.isCommitter
    }
  end
end
