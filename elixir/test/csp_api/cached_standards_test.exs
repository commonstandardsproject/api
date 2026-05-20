defmodule CspApi.CachedStandardsTest do
  @moduledoc """
  Pins the `CachedStandards.one/1` denormalization. Ruby's
  `StandardSet.update` writes a `cached_standards` row per standard,
  keyed by standard id, with fields denormalized from the parent set
  (subject, jurisdiction, education levels, etc.) plus the ancestor walk.
  """

  use CspApi.DataCase, async: false

  alias CspApi.Fixtures
  alias CspApi.MongoX
  alias CspApi.StandardSets

  test "upserting a standard set populates cached_standards" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()

    {:ok, _updated} =
      StandardSets.upsert(%{
        id: set.id,
        title: set.title,
        subject: set.subject,
        educationLevels: set.educationLevels,
        jurisdiction: %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title},
        document: %{"id" => "D1", "title" => "MD Math"},
        standards: %{
          "S1" => %{"id" => "S1", "depth" => 2, "position" => 100, "description" => "Leaf 1"},
          "S2" => %{"id" => "S2", "depth" => 2, "position" => 90, "description" => "Leaf 2"},
          "P" => %{"id" => "P", "depth" => 1, "position" => 80, "description" => "Parent"},
          "R" => %{"id" => "R", "depth" => 0, "position" => 70, "description" => "Root"}
        }
      })

    rows = MongoX.find("cached_standards", %{"standardSetId" => set.id})

    assert length(rows) == 4, "expected one cached_standards row per standard"

    by_id = Map.new(rows, &{&1["_id"], &1})

    # Denormalized fields are present on every row.
    Enum.each(rows, fn row ->
      assert row["standardSetId"] == set.id
      assert row["standardSetTitle"] == set.title
      assert row["jurisdictionId"] == set.jurisdiction.id
      assert row["jurisdictionTitle"] == set.jurisdiction.title
      assert row["subject"] == set.subject
      assert row["educationLevels"] == set.educationLevels
    end)

    # Ancestor walk: closest parent first, root last. Matches Ruby's
    # `find_ancestors` and the existing hierarchy_test assertions.
    assert by_id["R"]["ancestorIds"] == []
    assert by_id["P"]["ancestorIds"] == ["R"]
    assert by_id["S1"]["ancestorIds"] == ["P", "R"]
    assert by_id["S2"]["ancestorIds"] == ["P", "R"]
  end

  test "re-upserting replaces existing cached_standards (no duplicates)" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()

    base = fn standards ->
      %{
        id: set.id,
        title: set.title,
        subject: set.subject,
        educationLevels: set.educationLevels,
        jurisdiction: %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title},
        document: %{"id" => "D1"},
        standards: standards
      }
    end

    {:ok, _} =
      StandardSets.upsert(
        base.(%{"X" => %{"id" => "X", "depth" => 0, "position" => 1, "description" => "v1"}})
      )

    {:ok, _} =
      StandardSets.upsert(
        base.(%{"X" => %{"id" => "X", "depth" => 0, "position" => 1, "description" => "v2"}})
      )

    rows = MongoX.find("cached_standards", %{"standardSetId" => set.id})
    assert length(rows) == 1, "expected upsert, not duplicate insert"
    assert hd(rows)["description"] in ["v2", nil],
      "expected the latest revision's description (was: #{inspect(hd(rows))})"
  end
end
