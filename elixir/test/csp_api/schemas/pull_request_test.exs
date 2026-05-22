defmodule CspApi.Schemas.PullRequestTest do
  use ExUnit.Case, async: true

  alias CspApi.Schemas.PullRequest

  test "requires submitterId, submitterName, status" do
    cs = PullRequest.changeset(%PullRequest{}, %{})
    refute cs.valid?
    assert Keyword.has_key?(cs.errors, :submitterId)
    assert Keyword.has_key?(cs.errors, :submitterName)
    # status has a default of "draft" via the schema, so it isn't missing
    # by default. Force it to nil to assert the inclusion check.
    cs2 = PullRequest.changeset(%PullRequest{}, %{status: nil})
    assert Keyword.has_key?(cs2.errors, :status)
  end

  test "rejects unknown status" do
    cs =
      PullRequest.changeset(%PullRequest{}, %{
        submitterId: "u",
        submitterName: "n",
        status: "not-a-status"
      })

    refute cs.valid?
    assert Keyword.has_key?(cs.errors, :status)
  end

  test "accepts known statuses" do
    for s <- PullRequest.statuses() do
      cs =
        PullRequest.changeset(%PullRequest{}, %{
          submitterId: "u",
          submitterName: "n",
          status: s
        })

      assert cs.valid?, "expected #{s} to be valid; got errors #{inspect(cs.errors)}"
    end
  end
end
