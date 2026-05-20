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
          "standards" => %{},
          "jurisdiction" => %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title}
        }
      })

    {:ok, _} = PullRequests.change_status(pr.id, "approved", "looks good", true)

    indexed = Process.get(:algolia_indexed, [])
    assert length(indexed) == 1, "expected the approved set to be indexed once"
    {coll, doc} = hd(indexed)
    assert coll == "common-standards-project"
    assert doc["id"] == set.id
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
