defmodule CspApiWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Authenticates the request by looking up the user whose `apiKey` matches
  the `Api-Key` header. Stores the user on `conn.assigns[:current_user]`.

  Mirrors the `before do ... end` block in `api/api.rb`.
  """

  import Plug.Conn

  alias CspApi.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    key = get_key(conn)

    case Users.by_api_key(key) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            error: "Unauthorized: Not a valid auth key. Sign up at commonstandardsproject.com"
          })
        )
        |> halt()

      user ->
        # The Ruby app uses _id as id; expose both for downstream code.
        user = Map.put(user, "id", user["_id"])
        assign(conn, :current_user, user)
    end
  end

  defp get_key(conn) do
    case get_req_header(conn, "api-key") do
      [k | _] when is_binary(k) and k != "" -> k
      _ -> conn.params["api-key"] || conn.params["apiKey"]
    end
  end
end
