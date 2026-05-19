defmodule CspApiWeb.ActivityJSON do
  @moduledoc "Mirrors `api/entities/activity.rb`."

  def full(a) do
    %{
      "id" => a["id"],
      "createdAt" => a["createdAt"],
      "type" => a["type"],
      "status" => a["status"],
      "title" => a["title"],
      "userId" => a["userId"],
      "userName" => a["userName"]
    }
  end
end
