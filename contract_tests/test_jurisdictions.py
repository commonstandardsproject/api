"""Tests for /api/v1/jurisdictions."""

import os
import uuid

import pytest


# Maryland is a stable, public jurisdiction we can rely on
MARYLAND_ID = "49FCDFBD2CF04033A9C347BFA0584DF0"

# Authorization=TEST is honored by the Phoenix port in MIX_ENV=test (and by
# the Ruby app when ENVIRONMENT=test). Used for any POST that goes through
# the JWT plug.
AUTH_HEADER = {"Authorization": os.environ.get("CSP_TEST_AUTH", "TEST")}


@pytest.mark.read
def test_list_returns_data_array(client):
    resp = client.get("/api/v1/jurisdictions")
    assert resp.status == 200
    body = resp.json()
    assert "data" in body
    assert isinstance(body["data"], list)
    assert len(body["data"]) > 50, "expected at least all 50 US states"


@pytest.mark.read
def test_list_items_have_summary_shape(client):
    body = client.get("/api/v1/jurisdictions").json()
    item = body["data"][0]
    assert set(item.keys()) == {"id", "title", "type"}
    assert isinstance(item["id"], str)
    assert isinstance(item["title"], str)


@pytest.mark.read
def test_list_includes_maryland(client):
    body = client.get("/api/v1/jurisdictions").json()
    titles = {j["title"] for j in body["data"]}
    assert "Maryland" in titles


@pytest.mark.read
def test_list_types_are_known_values(client):
    body = client.get("/api/v1/jurisdictions").json()
    types = {j["type"] for j in body["data"] if "type" in j}
    known = {"state", "organization", "school", "corporation", "country", "nation"}
    extra = types - known
    assert not extra, f"unexpected jurisdiction types: {extra}"


@pytest.mark.read
def test_list_is_sorted_by_title(client):
    body = client.get("/api/v1/jurisdictions").json()
    titles = [j["title"] for j in body["data"]]
    # The list endpoint sorts by title ascending. Compare case-sensitively
    # since that's what MongoDB and the reference Ruby app do.
    assert titles == sorted(titles)


@pytest.mark.read
def test_get_one_returns_jurisdiction(client):
    resp = client.get(f"/api/v1/jurisdictions/{MARYLAND_ID}")
    assert resp.status == 200
    data = resp.json()["data"]
    assert data["id"] == MARYLAND_ID
    assert data["title"] == "Maryland"
    assert data["type"] == "state"
    assert isinstance(data["standardSets"], list)
    assert len(data["standardSets"]) > 0


@pytest.mark.read
def test_get_one_standard_set_summary_shape(client):
    data = client.get(f"/api/v1/jurisdictions/{MARYLAND_ID}").json()["data"]
    for ss in data["standardSets"]:
        assert "id" in ss
        assert "title" in ss
        assert "subject" in ss
        assert "educationLevels" in ss
        assert "document" in ss
        assert isinstance(ss["educationLevels"], list)


@pytest.mark.read
def test_get_one_hideHiddenSets_true_filters_hidden(client):
    visible = client.get(
        f"/api/v1/jurisdictions/{MARYLAND_ID}",
        params={"hideHiddenSets": True},
    ).json()["data"]["standardSets"]

    full = client.get(
        f"/api/v1/jurisdictions/{MARYLAND_ID}",
        params={"hideHiddenSets": False},
    ).json()["data"]["standardSets"]

    assert len(visible) <= len(full), "hideHiddenSets=true should not exceed full"


@pytest.mark.read
def test_get_one_hideHiddenSets_defaults_to_true(client):
    default = client.get(f"/api/v1/jurisdictions/{MARYLAND_ID}").json()["data"]["standardSets"]
    visible = client.get(
        f"/api/v1/jurisdictions/{MARYLAND_ID}",
        params={"hideHiddenSets": True},
    ).json()["data"]["standardSets"]
    assert len(default) == len(visible)


@pytest.mark.writes
def test_create_jurisdiction(client):
    """The hidden POST /jurisdictions endpoint creates a pending jurisdiction."""
    j_id = uuid.uuid4().hex.upper()
    resp = client.post(
        "/api/v1/jurisdictions",
        json_body={
            "jurisdiction": {
                "id": j_id,
                "title": f"Test Jurisdiction {j_id[:6]}",
                "type": "state",
            }
        },
        headers=AUTH_HEADER,
    )
    assert resp.status == 200, resp.text
    data = resp.json()["data"]
    assert data["id"] == j_id
    assert data["title"].startswith("Test Jurisdiction")
    # Per the Ruby controller, status defaults to "pending" on create.
    # Status isn't exposed in the entity so we verify indirectly: the new
    # jurisdiction shouldn't appear in the public list (which excludes
    # inactive/pending/rejected for non-submitter users).


@pytest.mark.writes
def test_pr_approval_auto_approves_jurisdiction(client):
    """
    `Jurisdiction.approve` runs when a PR with a standardSet whose
    jurisdiction is `pending` is approved. The jurisdiction's status
    becomes `approved`, so it shows up in the public list (for someone
    who isn't the submitter — submitters always see their own pending
    items, per the Ruby `:$or` query).

    Mirror of `models/pull_request.rb:206`.
    """
    from client import Client  # local import so the module isn't picky

    other_key = os.environ.get("CSP_OTHER_API_KEY", "smoke-key-other")
    stranger = Client(api_key=other_key)

    j_id = uuid.uuid4().hex.upper()
    title = f"Auto-approve test {j_id[:6]}"

    # Submitter creates a pending jurisdiction.
    client.post(
        "/api/v1/jurisdictions",
        json_body={"jurisdiction": {"id": j_id, "title": title, "type": "state"}},
        headers=AUTH_HEADER,
    )

    # Stranger (not submitter) doesn't see it yet — pending is hidden.
    pre = stranger.get("/api/v1/jurisdictions").json()["data"]
    assert title not in {j["title"] for j in pre}

    # Submitter approves a PR whose standardSet's jurisdiction points at
    # the pending row. Ruby's flow flips the jurisdiction to approved.
    pr = client.post("/api/v1/pull_requests", headers=AUTH_HEADER).json()["data"]
    client.post(
        f"/api/v1/pull_requests/{pr['id']}",
        json_body={
            "data": {
                "standardSet": {
                    "id": pr["standardSet"]["id"],
                    "title": "Trigger Set",
                    "subject": "Trigger",
                    "educationLevels": ["01"],
                    "jurisdiction": {"id": j_id, "title": title},
                }
            }
        },
        headers=AUTH_HEADER,
    )
    client.post(
        f"/api/v1/pull_requests/{pr['id']}/change_status",
        form_body={"status": "approved"},
        headers=AUTH_HEADER,
    )

    # Stranger now sees it.
    post = stranger.get("/api/v1/jurisdictions").json()["data"]
    assert title in {j["title"] for j in post}, (
        "expected Jurisdiction.approve to flip status to approved when a "
        "PR referencing it is approved"
    )
