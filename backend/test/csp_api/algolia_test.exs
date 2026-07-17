defmodule CspApi.AlgoliaTest do
  @moduledoc """
  Pins the `SendToAlgolia.standard_set/1` trigger.

  In Ruby, `PullRequest.change_status("approved", ...)` calls
  `StandardSet.update(...)` which in turn calls
  `SendToAlgolia.standard_set(set)`. The Elixir port should preserve the
  same trigger via a configurable adapter (the test adapter records calls
  in the process dictionary so the test can assert on them).
  """

  use CspApi.DataCase, async: false

  alias CspApi.Fixtures
  alias CspApi.PullRequests

  setup do
    # Default adapter for tests records what got sent.
    Application.put_env(:csp_api, :algolia_adapter, CspApi.Algolia.TestAdapter)
    Process.put(:algolia_indexed, [])
    :ok
  end

  test "approving a PR pushes the embedded standardSet to Algolia" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    user = Fixtures.insert_committer()

    {:ok, pr} =
      Fixtures.insert_pull_request_for(user, %{
        standardSet: %{
          "id" => set.id,
          "title" => set.title,
          "subject" => set.subject,
          "educationLevels" => set.educationLevels,
          # Copy the source set's standards so Algolia has rows to index.
          "standards" => set.standards,
          "jurisdiction" => %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title}
        }
      })

    {:ok, _} = PullRequests.change_status(pr.id, "approved", "looks good", true)

    indexed = Process.get(:algolia_indexed, [])
    assert length(indexed) == 1, "expected one index/2 call per approved set"
    {coll, batch} = hd(indexed)
    assert coll == "common-standards-project"

    # The batch should have one entry per standard in the set's
    # `standards` map. The fixture set has 4 standards.
    assert length(batch) == 4
    ids = Enum.map(batch, & &1["objectID"])
    assert "S1" in ids and "ROOT" in ids
  end

  test "rejecting a PR does NOT push to Algolia" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    user = Fixtures.insert_committer()
    {:ok, pr} = Fixtures.insert_pull_request_for(user, %{standardSet: %{"id" => set.id}})

    {:ok, _} = PullRequests.change_status(pr.id, "rejected", "nope", false)

    assert Process.get(:algolia_indexed, []) == []
  end

  describe "denormalize_standards/1 — static parity with Ruby SendToAlgolia" do
    # Mirrors `lib/send_to_algolia.rb:denormalize_standards`. Asserts the
    # full per-standard payload, not just shape — so any drift in keys,
    # nested structure, or _tags ordering will trip this test.

    @set %{
      id: "MD_D1_g1",
      title: "Grade 1",
      subject: "Math",
      normalizedSubject: "math",
      educationLevels: ["01"],
      jurisdiction: %{"id" => "MD", "title" => "Maryland"},
      document: %{"id" => "D1", "publicationStatus" => "published"},
      standards: %{
        "S1" => %{"id" => "S1", "depth" => 2, "position" => 100, "description" => "Leaf"},
        "P" => %{"id" => "P", "depth" => 1, "position" => 80, "description" => "Parent"},
        "R" => %{"id" => "R", "depth" => 0, "position" => 70, "description" => "Root"}
      }
    }

    test "S1 (leaf) carries the full denormalized parent + ancestor walk" do
      objects = CspApi.Algolia.denormalize_standards(@set)
      s1 = Enum.find(objects, &(&1["objectID"] == "S1"))

      # Originals preserved by the merge.
      assert s1["id"] == "S1"
      assert s1["depth"] == 2
      assert s1["position"] == 100
      assert s1["description"] == "Leaf"

      # Per-standard denormalized fields (mirror of `standard.merge({...})`).
      assert s1["objectID"] == "S1"
      assert s1["ancestorIds"] == ["P", "R"]
      assert s1["ancestorDescriptions"] == ["Parent", "Root"]
      assert s1["educationLevels"] == ["01"]
      assert s1["subject"] == "Math"
      assert s1["normalizedSubject"] == "math"

      # Embedded references — Ruby uses `{title:, id:}` for standardSet
      # and passes jurisdiction through as the raw hash.
      assert s1["standardSet"] == %{"title" => "Grade 1", "id" => "MD_D1_g1"}
      assert s1["jurisdiction"] == %{"id" => "MD", "title" => "Maryland"}

      # Ruby's `document` is *only* publicationStatus, nothing else.
      assert s1["document"] == %{"publicationStatus" => "published"}

      # Ruby flattens [ancestor_ids, _id, jurisdiction.id, educationLevels].
      assert s1["_tags"] == ["P", "R", "MD_D1_g1", "MD", "01"]
    end

    test "ROOT (top of hierarchy) has empty ancestorIds and ancestorDescriptions" do
      objects = CspApi.Algolia.denormalize_standards(@set)
      root = Enum.find(objects, &(&1["objectID"] == "R"))

      assert root["ancestorIds"] == []
      assert root["ancestorDescriptions"] == []
      # _tags still has the set-level entries even with no ancestors.
      assert root["_tags"] == ["MD_D1_g1", "MD", "01"]
    end

    test "one object per standard, all with consistent set-level fields" do
      objects = CspApi.Algolia.denormalize_standards(@set)
      assert length(objects) == 3

      Enum.each(objects, fn o ->
        assert o["subject"] == "Math"
        assert o["standardSet"] == %{"title" => "Grade 1", "id" => "MD_D1_g1"}
        assert o["jurisdiction"] == %{"id" => "MD", "title" => "Maryland"}
        assert o["document"] == %{"publicationStatus" => "published"}
      end)
    end

    test "missing document.publicationStatus becomes nil (matches Ruby's nil-default)" do
      set = put_in(@set, [:document], %{"id" => "D1"})

      objects = CspApi.Algolia.denormalize_standards(set)
      Enum.each(objects, fn o ->
        assert o["document"] == %{"publicationStatus" => nil}
      end)
    end
  end
end
