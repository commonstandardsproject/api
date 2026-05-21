defmodule CspApiWeb.SitemapController do
  @moduledoc """
  Port of the `/api/v1/sitemap.xml` Ruby endpoint. Returns an XML
  `urlset` containing one URL per standard set, pointing at the public
  search page. Public — no API key required.

  Output is formatted to match Ruby's Nokogiri `XML::Builder.to_xml`
  byte-for-byte:

    * `<?xml version="1.0"?>` (no `encoding` attribute — Nokogiri omits
      it by default)
    * Two-space indented `<url>` blocks, each wrapping `<loc>`
    * URL: literal `"` around the id; only `[`/`]` are percent-encoded
      (Ruby builds the URL with `%5B"...id..."%5D` interpolation, no
      URI escaping of the quotes)
  """
  use CspApiWeb, :controller

  alias CspApi.MongoX

  @doc false
  def show(conn, _params) do
    docs = MongoX.find("standard_sets", %{}, projection: %{"_id" => 1})

    url_blocks =
      Enum.map(docs, fn %{"_id" => id} ->
        ~s(  <url>\n    <loc>http://commonstandardsproject.com/search?ids=%5B"#{id}"%5D</loc>\n  </url>\n)
      end)

    body = [
      ~s(<?xml version="1.0"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      url_blocks,
      ~s(</urlset>\n)
    ]

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, IO.iodata_to_binary(body))
  end
end
