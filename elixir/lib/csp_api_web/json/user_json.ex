defmodule CspApiWeb.UserJSON do
  @moduledoc "Mirrors `api/entities/user.rb` from the Ruby app."

  def full(u) do
    %{
      "id" => u["_id"] || u["id"],
      "profile" => u["profile"],
      "email" => u["email"],
      "apiKey" => u["apiKey"],
      "algoliaApiKey" => u["algoliaApiKey"],
      "allowedOrigins" => u["allowedOrigins"] || [],
      "pullRequests" => u["pullRequests"] || [],
      "isCommitter" => u["isCommitter"] || false
    }
  end
end
