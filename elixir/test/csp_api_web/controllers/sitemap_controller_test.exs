defmodule CspApiWeb.SitemapControllerTest do
  @moduledoc """
  Pins the sitemap response: valid XML, one `<url>` per standard set,
  correct URL shape, namespace, content-type.

  The wire format is `:xmerl.export_simple/2` output (compact, no
  pretty-printing). Sitemap crawlers parse XML, not text, so the lack
  of Nokogiri-style indentation is invisible to consumers.
  """

  use CspApiWeb.ConnCase, async: false

  alias CspApi.Fixtures

  defp parse_xml(body) do
    {doc, _} = :xmerl_scan.string(String.to_charlist(body))
    doc
  end

  defp loc_urls(xml) do
    :xmerl_xpath.string(~c"//loc/text()", xml)
    |> Enum.map(fn {:xmlText, _, _, _, val, _} -> List.to_string(val) end)
  end

  test "emits one <url><loc> per standard set, namespaced and content-typed" do
    Fixtures.insert_jurisdiction()
    Fixtures.insert_standard_set()

    Fixtures.insert_standard_set(%{
      id: "ANOTHER_SET",
      title: "Other",
      subject: "Reading",
      educationLevels: ["02"]
    })

    # Sitemap crawlers don't send an Accept header — the `:accepts` plug
    # lets that through. Setting Accept: application/xml would 406.
    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/api/v1/sitemap.xml")

    assert conn.status == 200

    [content_type] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "text/xml"

    body = response(conn, 200)

    # Namespace declaration is on the root element.
    assert body =~ ~s(xmlns="http://www.sitemaps.org/schemas/sitemap/0.9")

    xml = parse_xml(body)
    urls = loc_urls(xml) |> Enum.sort()

    # Locs match the Ruby URL template: literal `"` around the id,
    # `[`/`]` pre-encoded. (Ruby builds these via string interpolation;
    # we do the same — xmerl leaves `"` in element text alone.)
    assert urls == [
             ~s(http://commonstandardsproject.com/search?ids=%5B"ANOTHER_SET"%5D),
             ~s(http://commonstandardsproject.com/search?ids=%5B"MD_D1_grade-01"%5D)
           ]
  end

  test "no standard sets → empty <urlset/>" do
    body =
      Phoenix.ConnTest.build_conn()
      |> get("/api/v1/sitemap.xml")
      |> response(200)

    xml = parse_xml(body)
    assert :xmerl_xpath.string(~c"//url", xml) == []
  end
end
