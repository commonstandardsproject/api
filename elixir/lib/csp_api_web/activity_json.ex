defmodule CspApiWeb.ActivityJSON do
  @moduledoc "Port of `api/entities/activity.rb`."

  alias CspApi.Schemas.Activity

  def show(%Activity{} = a) do
    %{
      "id" => a.id,
      "createdAt" => a.createdAt,
      "type" => a.type,
      "status" => a.status,
      "title" => a.title,
      "userId" => a.userId,
      "userName" => a.userName
    }
  end

  def show(a) when is_map(a) do
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
