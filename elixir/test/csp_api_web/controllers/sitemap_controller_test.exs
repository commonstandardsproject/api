defmodule CspApiWeb.SitemapControllerTest do
  @moduledoc """
  Pins the sitemap response format byte-for-byte against the Ruby Grape
  endpoint (which uses Nokogiri's XML::Builder.to_xml). Verified against
  live prod 2026-05-21: 24,296 URLs at 3,081,779 bytes, `cmp` clean.

  If this test starts failing, the wire format has drifted. SEO/sitemap
  consumers care about exact format here.
  """

  use CspApiWeb.ConnCase, async: false

  alias CspApi.Fixtures

  test "matches Ruby Nokogiri output verbatim" do
    Fixtures.insert_jurisdiction()
    Fixtures.insert_standard_set()

    Fixtures.insert_standard_set(%{
      id: "ANOTHER_SET",
      title: "Other",
      subject: "Reading",
      educationLevels: ["02"]
    })

    # Sitemap consumers (Google etc.) don't send an Accept header in
    # practice. The `:accepts` plug lets that through; setting Accept:
    # application/xml would make it 406.
    body =
      Phoenix.ConnTest.build_conn()
      |> get("/api/v1/sitemap.xml")
      |> response(200)

    expected =
      ~s(<?xml version="1.0"?>\n) <>
        ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n)

    assert String.starts_with?(body, expected)
    assert String.ends_with?(body, ~s(</urlset>\n))

    # Each url block: 2-space indented <url>, 4-space indented <loc>, the
    # id wrapped in literal " (not %22), [/] percent-encoded only.
    assert body =~
             ~s(  <url>\n    <loc>http://commonstandardsproject.com/search?ids=%5B"MD_D1_grade-01"%5D</loc>\n  </url>\n)

    assert body =~
             ~s(  <url>\n    <loc>http://commonstandardsproject.com/search?ids=%5B"ANOTHER_SET"%5D</loc>\n  </url>\n)

    # No %22 anywhere — that would mean the URL builder is escaping the
    # quotes Ruby leaves raw.
    refute body =~ "%22"
  end

  test "sets text/xml content-type (Ruby's Grape `content_type`)", %{conn: conn} do
    conn = get(conn, "/api/v1/sitemap.xml")
    [content_type] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "text/xml"
  end
end
