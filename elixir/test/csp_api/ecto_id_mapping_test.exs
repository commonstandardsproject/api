defmodule CspApi.EctoIdMappingTest do
  @moduledoc """
  Pins what mongodb_ecto does with `_id` ↔ `id` at the schema-load boundary
  for raw `:map` fields. The PR has been carrying a `normalize_id/1` helper
  that recursively renames `_id` → `id` on sub-documents, on the theory that
  Ecto only remaps the top-level primary key. This test verifies whether
  Ecto, in fact, recurses into `:map` fields and remaps `_id` automatically.

  PullRequest's `standardSet` is `field :standardSet, :map`, so the contents
  are opaque to the schema. If Ecto/mongodb_ecto does the rename anyway,
  `normalize_id` (and a View-side workaround) is unnecessary.
  """

  use CspApi.DataCase, async: false

  alias CspApi.{ID, Repo}
  alias CspApi.Schemas.PullRequest

  test "Ecto renames `_id` to `id` inside a :map field on load" do
    pr_id = ID.csp_uuid()
    set_id = ID.csp_uuid()
    doc_id = ID.csp_uuid()

    raw_doc = %{
      "_id" => pr_id,
      "submitterId" => "u1",
      "submitterName" => "Test User",
      "status" => "draft",
      "title" => "test",
      "createdAt" => "2026-05-21T00:00:00Z",
      "updatedAt" => "2026-05-21T00:00:00Z",
      "updatedAtDate" => "2026-05-21T00:00:00Z",
      "standardSet" => %{
        "_id" => set_id,
        "title" => "Math",
        "document" => %{
          "_id" => doc_id,
          "title" => "MD Math"
        }
      },
      "activities" => []
    }

    Mongo.Ecto.command(Repo, insert: "pull_requests", documents: [raw_doc])

    pr = Repo.get!(PullRequest, pr_id)

    # Top-level: Ecto's schema primary key is :id, so this is the well-known
    # remap path and should work.
    assert pr.id == pr_id

    # The question: does Ecto recurse into the :map field and remap there too?
    assert pr.standardSet["id"] == set_id,
      "expected mongodb_ecto to rename `_id` → `id` inside the :map field, but standardSet was: #{inspect(pr.standardSet)}"

    # And one level deeper, inside a nested map within the :map field:
    assert pr.standardSet["document"]["id"] == doc_id,
      "expected the rename to recurse into nested maps inside :map fields, but document was: #{inspect(pr.standardSet["document"])}"
  end
end
