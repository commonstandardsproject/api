defmodule CspApiWeb.StandardSetsControllerTest do
  use CspApiWeb.ConnCase, async: false

  alias CspApi.Fixtures

  setup do
    Fixtures.insert_jurisdiction()
    Fixtures.insert_standard_set()
    :ok
  end

  test "GET /standard_sets/:id returns the set with ancestor ids filled in", %{conn: conn} do
    %{"data" => data} =
      conn |> get("/api/v1/standard_sets/MD_D1_grade-01") |> json_response(200)

    assert data["id"] == "MD_D1_grade-01"
    assert data["title"] == "Grade 1"
    assert is_map(data["standards"])
    assert data["jurisdiction"] == %{"id" => "MD", "title" => "Maryland"}

    s1 = data["standards"]["S1"]
    s2 = data["standards"]["S2"]
    assert s1["parentId"] == "CL"
    assert s2["parentId"] == "CL"
    assert s1["ancestorIds"] == ["CL", "ROOT"]
    assert s2["ancestorIds"] == ["CL", "ROOT"]

    assert data["standards"]["ROOT"]["ancestorIds"] == []
    assert is_nil(data["standards"]["ROOT"]["parentId"])
  end

  test "GET /standard_sets/:id?standardsAsArray=true returns a list", %{conn: conn} do
    %{"data" => data} =
      conn
      |> get("/api/v1/standard_sets/MD_D1_grade-01?standardsAsArray=true")
      |> json_response(200)

    assert is_list(data["standards"])
    positions = Enum.map(data["standards"], & &1["position"])
    assert positions == Enum.sort(positions, :desc)
  end

  test "unknown id returns 200 with an empty data object", %{conn: conn} do
    assert %{"data" => %{}} ==
             conn
             |> get("/api/v1/standard_sets/does-not-exist")
             |> json_response(200)
  end
end
