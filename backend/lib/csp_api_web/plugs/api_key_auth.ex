defmodule CspApiWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Authenticates by `Api-Key` header (or `api-key` query param), and
  increments the matching user's `requestCount`. Sets
  `conn.assigns[:current_user]` on success.

  Also enforces the Origin check from `api/api.rb`'s `before` block: if
  an `Origin` header is set, the request is rejected unless the origin is
  one of the canonical `commonstandardsproject.com` URLs or appears in the
  user's `allowedOrigins`. Skipped in dev (matching Ruby's
  `env["ENVIRONMENT"] != "development"` guard).

  Bug-for-bug with `api/api.rb`: a missing or empty key still hits Mongo
  with `{apiKey: nil}`, which matches a user document that has no
  `apiKey` field. In production this lets unkeyed requests succeed if such
  a document exists; we replicate that exactly rather than silently
  closing the hole.
  """

  import Plug.Conn

  alias CspApi.Users

  @canonical_origins ~w(
    http://commonstandardsproject.com
    https://commonstandardsproject.com
    http://www.commonstandardsproject.com
    https://www.commonstandardsproject.com
  )

  def init(opts), do: opts

  def call(conn, _opts) do
    key = get_key(conn)

    case Users.by_api_key_and_bump(key) do
      nil ->
        unauthorized(conn, "Unauthorized: Not a valid auth key. Sign up at commonstandardsproject.com")

      user ->
        case check_origin(conn, user) do
          :ok -> assign(conn, :current_user, user)
          :forbidden -> unauthorized(conn, "Unauthorized: Origin isn't an allowed origin.")
        end
    end
  end

  defp get_key(conn) do
    case get_req_header(conn, "api-key") do
      [k | _] when is_binary(k) and k != "" -> k
      _ -> conn.params["api-key"] || conn.params["apiKey"]
    end
  end

  defp check_origin(conn, user) do
    origin =
      case get_req_header(conn, "origin") do
        [o | _] -> o
        _ -> nil
      end

    cond do
      # Runtime config (default `false`). Set `dev_origin_bypass?: true` in
      # `config/dev.exs` to skip the Origin check locally. We can't use
      # `Mix.env/0` here — it isn't callable from a release.
      Application.get_env(:csp_api, :dev_origin_bypass?, false) -> :ok
      is_nil(origin) -> :ok
      origin in @canonical_origins -> :ok
      origin in (user.allowedOrigins || []) -> :ok
      true -> :forbidden
    end
  end

  defp unauthorized(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: message}))
    |> halt()
  end
end
