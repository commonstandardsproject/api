"""Authentication / API-key behavior."""

import pytest

from client import Client


@pytest.mark.read
def test_valid_api_key_returns_200(client):
    resp = client.get("/api/v1/jurisdictions")
    assert resp.status == 200
    body = resp.json()
    assert "data" in body
    assert isinstance(body["data"], list)


@pytest.mark.read
def test_invalid_api_key_returns_401(client):
    resp = client.get("/api/v1/jurisdictions", api_key="not-a-real-key")
    assert resp.status == 401
    body = resp.json()
    assert "error" in body
    assert "Unauthorized" in body["error"]


@pytest.mark.read
def test_swagger_doc_is_public(client):
    resp = client.get("/api/v1/swagger_doc", api_key=None)
    assert resp.status == 200


@pytest.mark.read
def test_disallowed_origin_returns_401(client):
    """
    The Ruby `before` hook rejects requests when:
      * ENVIRONMENT != development
      * an `Origin` header is set
      * the Origin is not in the user's `allowedOrigins`
      * and not one of the four commonstandardsproject.com canonical URLs

    Mirror that here: a request with `Origin: https://evil.example.com`
    from a user whose allowedOrigins doesn't include it should 401.
    """
    resp = client.request(
        "GET",
        "/api/v1/jurisdictions",
        headers={"Origin": "https://evil.example.com"},
    )
    assert resp.status == 401, (
        f"expected 401 for Origin not in allowedOrigins, got {resp.status}"
    )


@pytest.mark.read
def test_commonstandardsproject_origin_allowed(client):
    """The canonical commonstandardsproject.com origins bypass the check."""
    for origin in (
        "http://commonstandardsproject.com",
        "https://commonstandardsproject.com",
        "http://www.commonstandardsproject.com",
        "https://www.commonstandardsproject.com",
    ):
        resp = client.request("GET", "/api/v1/jurisdictions", headers={"Origin": origin})
        assert resp.status == 200, (
            f"expected 200 for canonical origin {origin}, got {resp.status}"
        )
