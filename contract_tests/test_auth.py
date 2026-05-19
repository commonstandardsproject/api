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
