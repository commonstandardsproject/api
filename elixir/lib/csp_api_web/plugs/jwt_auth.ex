defmodule CspApiWeb.Plugs.JwtAuth do
  @moduledoc """
  Verifies the `Authorization` header on mutating endpoints.

  When `:csp_api, :auth, jwt_test_bypass?` is `true`, an
  `Authorization: TEST` header bypasses verification — this matches the
  Ruby spec's `Authorization=TEST` shortcut. The bypass is a compile-time
  config flag, not an env var, so a stray `MIX_ENV=test` at runtime can't
  open it up.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    auth =
      case get_req_header(conn, "authorization") do
        [v | _] -> v
        _ -> nil
      end

    cond do
      auth == "TEST" and test_bypass?() ->
        conn

      is_nil(auth) ->
        unauthorized(conn, "No Authorization Token")

      true ->
        verify_token(conn, auth)
    end
  end

  defp test_bypass? do
    Application.get_env(:csp_api, :auth, [])[:jwt_test_bypass?] == true
  end

  defp verify_token(conn, "Bearer " <> token), do: verify_token(conn, token)

  defp verify_token(conn, token) do
    auth = Application.get_env(:csp_api, :auth, [])
    secret = auth[:jwt_secret]
    client_id = auth[:jwt_client_id]

    if is_nil(secret) do
      unauthorized(conn, "Invalid Token")
    else
      decoded_secret = Base.url_decode64!(secret, padding: false)
      signer = Joken.Signer.create("HS256", decoded_secret)

      case Joken.verify_and_validate(%{}, token, signer) do
        {:ok, %{"aud" => ^client_id}} -> conn
        _ -> unauthorized(conn, "Invalid Token")
      end
    end
  rescue
    _ -> unauthorized(conn, "Invalid Token")
  end

  defp unauthorized(conn, msg) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: msg}))
    |> halt()
  end
end
