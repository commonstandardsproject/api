defmodule CspApi.HierarchyTest do
  use ExUnit.Case, async: true

  alias CspApi.Hierarchy

  test "returns empty for nil and empty maps" do
    assert Hierarchy.add_ancestor_ids(nil) == %{}
    assert Hierarchy.add_ancestor_ids(%{}) == %{}
  end

  test "fills ancestorIds walking position-desc forward" do
    # CSP standards are stored with descending position from leaves to
    # roots: children sit at the top of the descending-position list and
    # their parents come after. The hierarchy walker uses that ordering to
    # discover ancestors.
    standards = %{
      "S1" => %{"id" => "S1", "depth" => 2, "position" => 100},
      "S2" => %{"id" => "S2", "depth" => 2, "position" => 90},
      "CL" => %{"id" => "CL", "depth" => 1, "position" => 80},
      "ROOT" => %{"id" => "ROOT", "depth" => 0, "position" => 70}
    }

    result = Hierarchy.add_ancestor_ids(standards)

    assert result["ROOT"]["ancestorIds"] == []
    assert is_nil(result["ROOT"]["parentId"])

    assert result["CL"]["ancestorIds"] == ["ROOT"]
    assert result["CL"]["parentId"] == "ROOT"

    assert result["S1"]["ancestorIds"] == ["CL", "ROOT"]
    assert result["S1"]["parentId"] == "CL"

    assert result["S2"]["ancestorIds"] == ["CL", "ROOT"]
    assert result["S2"]["parentId"] == "CL"
  end

  test "skips same-depth siblings while walking" do
    # Two depth-2 leaves followed by their parent and grandparent — the
    # walker shouldn't add the sibling as an ancestor.
    standards = %{
      "S1" => %{"id" => "S1", "depth" => 2, "position" => 100},
      "S2" => %{"id" => "S2", "depth" => 2, "position" => 95},
      "S3" => %{"id" => "S3", "depth" => 2, "position" => 90},
      "CL" => %{"id" => "CL", "depth" => 1, "position" => 80},
      "ROOT" => %{"id" => "ROOT", "depth" => 0, "position" => 70}
    }

    result = Hierarchy.add_ancestor_ids(standards)

    assert result["S1"]["ancestorIds"] == ["CL", "ROOT"]
    assert result["S2"]["ancestorIds"] == ["CL", "ROOT"]
    assert result["S3"]["ancestorIds"] == ["CL", "ROOT"]
  end

  test "matches the live CSP sample for Maryland math grade 1" do
    # Trimmed sample of the standards map the live API returns for
    # 49FCDFBD2CF04033A9C347BFA0584DF0_D2604890_grade-01. Values for
    # ancestorIds and parentId have been blanked out so the test
    # reconstructs them from scratch.
    standards = %{
      "1G_A_3" => %{"id" => "1G_A_3", "depth" => 2, "position" => 48_000},
      "1G_A_2" => %{"id" => "1G_A_2", "depth" => 2, "position" => 47_000},
      "1G_A_1" => %{"id" => "1G_A_1", "depth" => 2, "position" => 46_000},
      "1G_A" => %{"id" => "1G_A", "depth" => 1, "position" => 45_000},
      "Geom" => %{"id" => "Geom", "depth" => 0, "position" => 44_000}
    }

    result = Hierarchy.add_ancestor_ids(standards)

    assert result["1G_A_3"]["ancestorIds"] == ["1G_A", "Geom"]
    assert result["1G_A_3"]["parentId"] == "1G_A"
    assert result["1G_A"]["ancestorIds"] == ["Geom"]
    assert result["1G_A"]["parentId"] == "Geom"
    assert result["Geom"]["ancestorIds"] == []
  end
end
