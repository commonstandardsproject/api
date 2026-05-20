defmodule CspApiWeb.SitemapController do
  @moduledoc """
  Port of the `/api/v1/sitemap.xml` Ruby endpoint. Returns an XML
  `urlset` containing one URL per standard set, pointing at the public
  search page. Public — no API key required.
  """
  use CspApiWeb, :controller

  alias CspApi.MongoX

  @doc false
  def show(conn, _params) do
    docs = MongoX.find("standard_sets", %{}, projection: %{"_id" => 1})

    body =
      [
        ~s(<?xml version="1.0" encoding="UTF-8"?>),
        ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      ] ++
        Enum.map(docs, fn %{"_id" => id} ->
          encoded = URI.encode_www_form(~s(["#{id}"]))
          ~s(<url><loc>http://commonstandardsproject.com/search?ids=#{encoded}</loc></url>)
        end) ++ [~s(</urlset>)]

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, IO.iodata_to_binary(body))
  end
end
