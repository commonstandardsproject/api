"""Tests for /api/v1/users."""

import os
import uuid

import pytest


AUTH_HEADER = {"Authorization": os.environ.get("CSP_TEST_AUTH", "TEST")}


@pytest.mark.writes
def test_signed_in_creates_user(client):
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    resp = client.post(
        "/api/v1/users/signed_in",
        json_body={"profile": {"email": email, "name": "Contract Tester"}},
        headers=AUTH_HEADER,
    )
    assert resp.status == 200
    data = resp.json()["data"]
    assert data["email"] == email
    assert data["apiKey"], "expected an api key to be generated"
    assert data["id"]


@pytest.mark.writes
def test_signed_in_is_idempotent_for_existing_email(client):
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    first = client.post(
        "/api/v1/users/signed_in",
        json_body={"profile": {"email": email, "name": "Contract Tester"}},
        headers=AUTH_HEADER,
    ).json()["data"]
    second = client.post(
        "/api/v1/users/signed_in",
        json_body={"profile": {"email": email, "name": "Contract Tester 2"}},
        headers=AUTH_HEADER,
    ).json()["data"]
    assert first["id"] == second["id"]
    assert first["apiKey"] == second["apiKey"]


@pytest.mark.writes
def test_lookup_user_by_email(client):
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    created = client.post(
        "/api/v1/users/signed_in",
        json_body={"profile": {"email": email, "name": "Contract Tester"}},
        headers=AUTH_HEADER,
    ).json()["data"]
    resp = client.get(f"/api/v1/users/{email}", headers=AUTH_HEADER)
    assert resp.status == 200
    assert resp.json()["data"]["id"] == created["id"]


@pytest.mark.writes
def test_allowed_origins_can_be_updated(client):
    email = f"test-{uuid.uuid4().hex[:8]}@example.com"
    created = client.post(
        "/api/v1/users/signed_in",
        json_body={"profile": {"email": email, "name": "Contract Tester"}},
        headers=AUTH_HEADER,
    ).json()["data"]
    resp = client.post(
        f"/api/v1/users/{created['id']}/allowed_origins",
        json_body={"data": ["https://example.org"]},
        headers=AUTH_HEADER,
    )
    assert resp.status == 200
    assert "https://example.org" in resp.json()["data"]["allowedOrigins"]
