"""Tests for /api/v1/standard_sets."""

import pytest


# Maryland math grade 1 — stable, public, and shipped in the Ruby app's swagger
# defaults.
MD_MATH_G1 = "49FCDFBD2CF04033A9C347BFA0584DF0_D2604890_grade-01"


@pytest.mark.read
def test_get_one_returns_standard_set(client):
    resp = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}")
    assert resp.status == 200
    data = resp.json()["data"]
    assert data["id"] == MD_MATH_G1
    assert data["title"] == "Grade 1"
    assert "Math" in data["subject"]
    assert "01" in data["educationLevels"]


@pytest.mark.read
def test_top_level_shape(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    expected_keys = {
        "id",
        "title",
        "subject",
        "normalizedSubject",
        "educationLevels",
        "cspStatus",
        "license",
        "document",
        "jurisdiction",
        "standards",
    }
    assert expected_keys.issubset(set(data.keys()))


@pytest.mark.read
def test_jurisdiction_nested_summary(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    assert data["jurisdiction"]["id"] == "49FCDFBD2CF04033A9C347BFA0584DF0"
    assert data["jurisdiction"]["title"] == "Maryland"


@pytest.mark.read
def test_document_shape(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    doc = data["document"]
    assert doc["id"] == "D2604890"
    assert "title" in doc
    assert "asnIdentifier" in doc
    assert "publicationStatus" in doc


@pytest.mark.read
def test_license_shape(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    lic = data["license"]
    assert {"title", "URL", "rightsHolder"}.issubset(set(lic.keys()))


@pytest.mark.read
def test_standards_default_is_dict(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    assert isinstance(data["standards"], dict)
    assert len(data["standards"]) > 0
    # key matches id inside
    for k, v in data["standards"].items():
        assert v["id"] == k


@pytest.mark.read
def test_standards_as_array_param_returns_list(client):
    data = client.get(
        f"/api/v1/standard_sets/{MD_MATH_G1}",
        params={"standardsAsArray": True},
    ).json()["data"]
    assert isinstance(data["standards"], list)
    assert len(data["standards"]) > 0


@pytest.mark.read
def test_standard_has_required_fields(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    for std in data["standards"].values():
        assert "id" in std
        assert "depth" in std
        assert "ancestorIds" in std
        assert isinstance(std["ancestorIds"], list)


@pytest.mark.read
def test_ancestor_ids_are_consistent_with_parent_ids(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    standards = data["standards"]

    # Independently rebuild ancestorIds from parentId and compare. This is the
    # job of lib/standard_hierarchy.rb in the Ruby app.
    for std in standards.values():
        expected = []
        cursor = std.get("parentId")
        while cursor:
            expected.append(cursor)
            parent = standards.get(cursor)
            if parent is None:
                break
            cursor = parent.get("parentId")
        assert std["ancestorIds"] == expected, (
            f"standard {std['id']} has inconsistent ancestor chain: "
            f"got {std['ancestorIds']}, expected {expected}"
        )


@pytest.mark.read
def test_root_standards_have_empty_ancestors(client):
    data = client.get(f"/api/v1/standard_sets/{MD_MATH_G1}").json()["data"]
    roots = [s for s in data["standards"].values() if not s.get("parentId")]
    assert roots, "expected at least one root-level standard"
    for r in roots:
        assert r["ancestorIds"] == []


@pytest.mark.read
def test_missing_id_returns_empty_data(client):
    """The Ruby app returns 200 with {data: {}} for unknown IDs."""
    resp = client.get("/api/v1/standard_sets/this-id-does-not-exist-anywhere-XYZ")
    assert resp.status == 200
    assert resp.json() == {"data": {}}
