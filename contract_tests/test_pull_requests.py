"""Tests for /api/v1/pull_requests.

These are write-side tests (creating, updating, status-changing pull requests).
They run only when ``CSP_ALLOW_WRITES=1`` is set, since they mutate state.

The reference Ruby suite is /home/user/api/spec/controllers/pull_requests.rb;
these mirror it as black-box HTTP tests so the Elixir port can be validated
against the same behavior.
"""

import os
import uuid

import pytest


# The Ruby spec uses Authorization=TEST as a dev/test bypass for the JWT step.
# That bypass is only honored when ENVIRONMENT=test on the server side. The
# Phoenix port carries the same test-mode bypass.
AUTH_HEADER = {"Authorization": os.environ.get("CSP_TEST_AUTH", "TEST")}


def _new_pr_id() -> str:
    return uuid.uuid4().hex.upper()


@pytest.mark.writes
def test_create_blank_pull_request(client):
    resp = client.post("/api/v1/pull_requests", headers=AUTH_HEADER)
    assert resp.status == 201 or resp.status == 200
    data = resp.json()["data"]

    assert "id" in data
    assert data["status"] == "draft"
    assert data["submitterId"]
    assert data["submitterEmail"]
    # The first activity records the creation
    assert data["activities"], "expected at least the creation activity"
    assert data["activities"][0]["type"] == "created"


@pytest.mark.writes
def test_get_pull_request_by_id(client):
    created = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.get(f"/api/v1/pull_requests/{created['id']}", headers=AUTH_HEADER)
    assert resp.status == 200
    data = resp.json()["data"]
    assert data["id"] == created["id"]


@pytest.mark.writes
def test_list_user_pull_requests(client):
    created = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.get(
        f"/api/v1/pull_requests/user/{created['submitterId']}",
        headers=AUTH_HEADER,
    )
    assert resp.status == 200
    body = resp.json()
    ids = {pr["id"] for pr in body["data"]}
    assert created["id"] in ids


@pytest.mark.writes
def test_submit_changes_status(client):
    pr = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.post(f"/api/v1/pull_requests/{pr['id']}/submit", headers=AUTH_HEADER)
    assert resp.status == 200
    assert resp.json()["data"]["status"] == "approval-requested"


@pytest.mark.writes
def test_comment_appends_activity(client):
    pr = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.post(
        f"/api/v1/pull_requests/{pr['id']}/comment",
        form_body={"comment": "looks great"},
        headers=AUTH_HEADER,
    )
    assert resp.status == 200
    data = resp.json()["data"]
    comments = [a for a in data["activities"] if a["type"] == "comment"]
    assert any(a["title"] == "looks great" for a in comments)


@pytest.mark.writes
def test_change_status_rejected(client):
    pr = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.post(
        f"/api/v1/pull_requests/{pr['id']}/change_status",
        form_body={"status": "rejected"},
        headers=AUTH_HEADER,
    )
    assert resp.status == 200
    assert resp.json()["data"]["status"] == "rejected"


@pytest.mark.writes
def test_change_status_invalid_rejected(client):
    pr = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    resp = client.post(
        f"/api/v1/pull_requests/{pr['id']}/change_status",
        form_body={"status": "totally-made-up"},
        headers=AUTH_HEADER,
    )
    # The Ruby PullRequest.change_status returns false on unknown status and
    # the endpoint returns the unchanged PR.
    assert resp.status == 200
    assert resp.json()["data"]["status"] == "draft"
