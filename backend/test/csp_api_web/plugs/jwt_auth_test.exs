defmodule CspApiWeb.Plugs.JwtAuthTest do
  @moduledoc """
  Round-trip JWT verification. Signs an HS256 token with a known secret
  via the same library `JwtAuth` uses (Joken), passes it through the
  plug, and asserts the resulting conn matches what we'd see in prod
  for a valid Auth0 token.

  The contract suite exercises only the `Authorization: TEST` bypass —
  the JWT verify path itself was previously untested.
  """

  use CspApiWeb.ConnCase, async: false

  alias CspApiWeb.Plugs.JwtAuth

  # Random fixed bytes — base64-url-encoded so the value mirrors the
  # `AUTH0_CLIENT_SECRET` shape that `runtime.exs` reads from env.
  @raw_secret <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>
  @encoded_secret Base.url_encode64(@raw_secret, padding: false)
  @client_id "test-client-abc123"

  setup do
    # Temporarily swap the test bypass off so the verify path actually
    # runs. Restore on exit so the rest of the suite keeps its `Authorization:
    # TEST` shortcut.
    prior = Application.get_env(:csp_api, :auth, [])

    Application.put_env(:csp_api, :auth,
      jwt_test_bypass?: false,
      jwt_secret: @encoded_secret,
      jwt_client_id: @client_id
    )

    on_exit(fn -> Application.put_env(:csp_api, :auth, prior) end)
    :ok
  end

  defp sign(claims) do
    signer = Joken.Signer.create("HS256", @raw_secret)
    {:ok, token, _} = Joken.encode_and_sign(claims, signer)
    token
  end

  defp call_with(auth) do
    Phoenix.ConnTest.build_conn()
    |> Plug.Conn.put_req_header("authorization", auth)
    |> JwtAuth.call(%{})
  end

  test "valid HS256 token with matching aud passes through" do
    token = sign(%{"aud" => @client_id, "exp" => future_unix()})
    conn = call_with(token)
    refute conn.halted
    assert conn.status == nil
  end

  test "Bearer prefix is stripped before verifying" do
    token = sign(%{"aud" => @client_id, "exp" => future_unix()})
    conn = call_with("Bearer " <> token)
    refute conn.halted
  end

  test "wrong aud is rejected with 401" do
    token = sign(%{"aud" => "someone-else", "exp" => future_unix()})
    conn = call_with(token)
    assert conn.halted
    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["error"] == "Invalid Token"
  end

  test "expired token is rejected" do
    token = sign(%{"aud" => @client_id, "exp" => past_unix()})
    conn = call_with(token)
    assert conn.halted
    assert conn.status == 401
  end

  test "tampered signature is rejected" do
    token = sign(%{"aud" => @client_id, "exp" => future_unix()})

    # Flip a byte in the signature segment.
    [header, body, sig] = String.split(token, ".")
    bad_sig = String.replace(sig, ~r/^./, "x")
    tampered = Enum.join([header, body, bad_sig], ".")

    conn = call_with(tampered)
    assert conn.halted
    assert conn.status == 401
  end

  test "garbage in Authorization is rejected" do
    conn = call_with("nonsense")
    assert conn.halted
    assert conn.status == 401
  end

  test "missing Authorization header is rejected with 'No Authorization Token'" do
    conn = JwtAuth.call(Phoenix.ConnTest.build_conn(), %{})
    assert conn.halted
    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["error"] == "No Authorization Token"
  end

  defp future_unix, do: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
  defp past_unix, do: DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.to_unix()
end
