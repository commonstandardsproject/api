"""Test for /api/v1/sitemap.xml (Ruby) — Phoenix port should match."""

import pytest


@pytest.mark.read
def test_sitemap_returns_xml(client):
    resp = client.get("/api/v1/sitemap.xml")
    assert resp.status == 200
    # Ruby sets `content_type "text/xml"`. Accept both `text/xml` and
    # `application/xml` since either is valid.
    ctype = resp.headers.get("content-type") or resp.headers.get("Content-Type") or ""
    assert "xml" in ctype.lower(), f"expected XML, got {ctype!r}"
    body = resp.text
    assert "<urlset" in body
    assert "commonstandardsproject.com/search?ids=" in body
