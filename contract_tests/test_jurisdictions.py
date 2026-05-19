"""Tests for /api/v1/jurisdictions."""

import pytest


# Maryland is a stable, public jurisdiction we can rely on
MARYLAND_ID = "49FCDFBD2CF04033A9C347BFA0584DF0"


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
