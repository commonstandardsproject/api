defmodule CspApiWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Authenticates by `Api-Key` header (or `api-key` query param), and
  increments the matching user's `requestCount`. Sets
  `conn.assigns[:current_user]` on success.

  Bug-for-bug with `api/api.rb`: a missing or empty key still hits Mongo
  with `{apiKey: nil}`, which matches a user document that has no
  `apiKey` field. In production this lets unkeyed requests succeed if such
  a document exists; we replicate that exactly rather than silently
  closing the hole.
  """

  import Plug.Conn

  alias CspApi.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    key = get_key(conn)

    case Users.by_api_key_and_bump(key) do
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
