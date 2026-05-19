defmodule CspApiWeb.JurisdictionsControllerTest do
  use CspApiWeb.ConnCase, async: false

  alias CspApi.Fixtures

  setup do
    Fixtures.insert_jurisdiction()
    Fixtures.insert_jurisdiction(%{
      "_id" => "AL",
      "title" => "Alabama",
      "type" => "state"
    })
    Fixtures.insert_jurisdiction(%{
      "_id" => "REJECTED",
      "title" => "Hidden jurisdiction",
      "status" => "rejected"
    })

    Fixtures.insert_standard_set()
    Fixtures.insert_standard_set(%{
      "_id" => "MD_D1_grade-02",
      "title" => "Grade 2",
      "educationLevels" => ["02"]
    })

    :ok
  end

  test "GET /jurisdictions lists approved jurisdictions sorted by title", %{conn: conn} do
    %{"data" => list} =
      conn
      |> get("/api/v1/jurisdictions")
      |> json_response(200)

    titles = Enum.map(list, & &1["title"])
    assert "Maryland" in titles
    assert "Alabama" in titles
    refute "Hidden jurisdiction" in titles
    assert titles == Enum.sort(titles)
  end

  test "GET /jurisdictions returns id/title/type only", %{conn: conn} do
    %{"data" => [first | _]} = json_response(get(conn, "/api/v1/jurisdictions"), 200)
    assert Map.keys(first) |> Enum.sort() == ["id", "title", "type"]
  end

  test "GET /jurisdictions/:id returns the jurisdiction and standardSets", %{conn: conn} do
    %{"data" => data} =
      conn
      |> get("/api/v1/jurisdictions/MD")
      |> json_response(200)

    assert data["id"] == "MD"
    assert data["title"] == "Maryland"
    assert length(data["standardSets"]) == 2

    [first | _] = data["standardSets"]
    assert "id" in Map.keys(first)
    assert "title" in Map.keys(first)
    assert "subject" in Map.keys(first)
    assert "document" in Map.keys(first)
    assert "educationLevels" in Map.keys(first)
  end

  test "GET /jurisdictions/:id with hideHiddenSets=false includes hidden sets", %{conn: conn} do
    # Mark one set hidden so the filter has work to do
    Mongo.update_one(
      :mongo,
      "standard_sets",
      %{"_id" => "MD_D1_grade-02"},
      %{"$set" => %{"cspStatus" => %{"value" => "hidden"}}}
    )

    %{"data" => default} =
      conn |> get("/api/v1/jurisdictions/MD") |> json_response(200)

    %{"data" => full} =
      conn
      |> get("/api/v1/jurisdictions/MD?hideHiddenSets=false")
      |> json_response(200)

    assert length(default["standardSets"]) < length(full["standardSets"])
  end
end
