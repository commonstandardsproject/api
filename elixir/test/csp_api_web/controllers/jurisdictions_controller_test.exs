defmodule CspApiWeb.JurisdictionsControllerTest do
  use CspApiWeb.ConnCase, async: false

  alias CspApi.Fixtures

  setup do
    Fixtures.insert_jurisdiction()
    Fixtures.insert_jurisdiction(%{id: "AL", title: "Alabama", type: "state"})
    Fixtures.insert_jurisdiction(%{id: "REJECTED", title: "Hidden", status: "rejected"})

    Fixtures.insert_standard_set()
    Fixtures.insert_standard_set(%{id: "MD_D1_grade-02", title: "Grade 2", educationLevels: ["02"]})
    :ok
  end

  test "GET /jurisdictions lists approved jurisdictions sorted by title", %{conn: conn} do
    %{"data" => list} =
      conn |> get("/api/v1/jurisdictions") |> json_response(200)

    titles = Enum.map(list, & &1["title"])
    assert "Maryland" in titles
    assert "Alabama" in titles
    refute "Hidden" in titles
    assert titles == Enum.sort(titles)
  end

  test "GET /jurisdictions returns id/title/type only", %{conn: conn} do
    %{"data" => [first | _]} = json_response(get(conn, "/api/v1/jurisdictions"), 200)
    assert Map.keys(first) |> Enum.sort() == ["id", "title", "type"]
  end

  test "GET /jurisdictions/:id returns the jurisdiction and standardSets", %{conn: conn} do
    %{"data" => data} =
      conn |> get("/api/v1/jurisdictions/MD") |> json_response(200)

    assert data["id"] == "MD"
    assert data["title"] == "Maryland"
    assert length(data["standardSets"]) == 2
  end

  test "GET /jurisdictions/:id with hideHiddenSets=false includes hidden sets", %{conn: conn} do
    # Mark one set hidden so the filter has work to do.
    {:ok, _} =
      Mongo.Ecto.command(Repo,
        update: "standard_sets",
        updates: [%{q: %{_id: "MD_D1_grade-02"}, u: %{"$set" => %{cspStatus: %{value: "hidden"}}}}]
      )

    %{"data" => default} = conn |> get("/api/v1/jurisdictions/MD") |> json_response(200)
    %{"data" => full} =
      conn |> get("/api/v1/jurisdictions/MD?hideHiddenSets=false") |> json_response(200)

    assert length(default["standardSets"]) < length(full["standardSets"])
  end

  test "GET /jurisdictions/:id returns {} for unknown id", %{conn: conn} do
    assert %{"data" => %{}} ==
             conn |> get("/api/v1/jurisdictions/does-not-exist") |> json_response(200)
  end
end
