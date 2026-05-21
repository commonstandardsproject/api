defmodule CspApiWeb.SitemapController do
  @moduledoc """
  Port of the `/api/v1/sitemap.xml` Ruby endpoint. Returns an XML
  `urlset` containing one URL per standard set, pointing at the public
  search page. Public — no API key required.

  Uses `:xmerl.export_simple/2` (Erlang stdlib) so XML escaping and the
  prolog are library-correct. The output is compact single-line XML
  rather than Nokogiri's pretty-printed form — sitemap crawlers (Google
  etc.) parse the XML structure rather than the whitespace, so the
  format change is invisible to consumers.

  The URL is built with a literal `"` around the id and a pre-encoded
  `%5B`/`%5D` for the JSON brackets, matching the Ruby app's URL string
  exactly (only the wrapping XML's formatting differs).
  """
  use CspApiWeb, :controller

  alias CspApi.MongoX

  @xmlns "http://www.sitemaps.org/schemas/sitemap/0.9"

  @doc false
  def show(conn, _params) do
    url_elements =
      "standard_sets"
      |> MongoX.find(%{}, projection: %{"_id" => 1})
      |> Enum.map(fn %{"_id" => id} ->
        {:url, [], [{:loc, [], [String.to_charlist(search_url(id))]}]}
      end)

    doc = {:urlset, [xmlns: String.to_charlist(@xmlns)], url_elements}

    body =
      [doc]
      |> :xmerl.export_simple(:xmerl_xml)
      |> IO.iodata_to_binary()

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, body)
  end

  defp search_url(id) do
    # Ruby: "http://.../search?ids=%5B\"#{doc["_id"]}\"%5D"
    # The brackets are pre-encoded; the quotes are literal text and
    # `:xmerl` will leave them alone in element content.
    ~s(http://commonstandardsproject.com/search?ids=%5B"#{id}"%5D)
  end
end
