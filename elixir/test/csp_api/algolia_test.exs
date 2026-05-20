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
end
