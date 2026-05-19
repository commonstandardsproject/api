defmodule CspApiWeb.Plugs.JwtAuth do
  @moduledoc """
  Verifies the `Authorization` header on mutating endpoints. In test
  environments an `Authorization: TEST` header bypasses verification — the
  Ruby app does the same so the rspec suite can hit POST endpoints
  without minting JWTs.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    env = Application.get_env(:csp_api, :environment, :prod)
    auth = case get_req_header(conn, "authorization") do
      [v | _] -> v
      _ -> nil
    end

    cond do
      env == :test and auth == "TEST" ->
        conn

      is_nil(auth) ->
        unauthorized(conn, "No Authorization Token")

      true ->
        verify_token(conn, auth)
    end
  end

  defp verify_token(conn, "Bearer " <> token), do: verify_token(conn, token)

  defp verify_token(conn, token) do
    secret = Application.get_env(:csp_api, :auth)[:jwt_secret]
    client_id = Application.get_env(:csp_api, :auth)[:jwt_client_id]

    cond do
      is_nil(secret) ->
        unauthorized(conn, "Invalid Token")

      true ->
        # Auth0 historically base64-url-decoded the secret before HS256.
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
