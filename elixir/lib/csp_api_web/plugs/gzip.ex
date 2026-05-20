defmodule CspApiWeb.Plugs.Gzip do
  @moduledoc """
  Gzips response bodies when the client signals support via
  `Accept-Encoding: gzip` and the response body is at least a few hundred
  bytes (below that the framing overhead isn't worth it).

  Skips when the response already has a `Content-Encoding` header (e.g.
  upstream already compressed) or when the body is empty.

  Mirrors `Rack::Deflater` from the Ruby app's `config.ru`.
  """

  import Plug.Conn

  @min_size 256

  def init(opts), do: opts

  def call(conn, _opts) do
    if accepts_gzip?(conn) do
      register_before_send(conn, &maybe_gzip/1)
    else
      conn
    end
  end

  defp accepts_gzip?(conn) do
    case get_req_header(conn, "accept-encoding") do
      [v | _] -> String.contains?(v, "gzip")
      _ -> false
    end
  end

  defp maybe_gzip(%Plug.Conn{resp_body: body} = conn) when body in [nil, ""], do: conn

  defp maybe_gzip(%Plug.Conn{resp_body: body} = conn) do
    # Phoenix.Controller.json/2 sets resp_body to an iodata list, not a
    # binary — coerce before measuring size.
    binary = IO.iodata_to_binary(body)

    cond do
      byte_size(binary) < @min_size ->
        conn

      List.keymember?(conn.resp_headers, "content-encoding", 0) ->
        conn

      true ->
        compressed = :zlib.gzip(binary)

        conn
        |> put_resp_header("content-encoding", "gzip")
        |> put_resp_header("vary", "Accept-Encoding")
        |> resp(conn.status, compressed)
    end
  end
end
