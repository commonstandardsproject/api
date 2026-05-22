"""Tests for /api/v1/standard_documents."""

import pytest


# A document referenced by the prod MD_MATH_G1 standard set. The
# contract seed creates a stub.
MD_DOC_ID = "D2604890"


@pytest.mark.read
def test_get_standard_document_returns_doc(client):
    resp = client.get(f"/api/v1/standard_documents/{MD_DOC_ID}")
    assert resp.status == 200
    data = resp.json()
    # The Ruby entity exposes `id`, `documentMeta`, `document`,
    # `standardSetQueries`.
    assert data.get("id") == MD_DOC_ID
    assert "document" in data


@pytest.mark.read
def test_get_standard_document_unknown_id_returns_empty(client):
    resp = client.get("/api/v1/standard_documents/this-id-does-not-exist-XYZ")
    assert resp.status == 200
    # Ruby returns `{}` (the entity over a nil doc renders nothing) — our
    # contract is the same. Either an empty body or empty data object.
    body = resp.json() or {}
    assert body in ({}, {"data": {}})
