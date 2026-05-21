defmodule CspApi.StandardSetsTest do
  @moduledoc """
  Pins the upsert path. The version bump uses `findAndModify` with `$inc`
  so concurrent upserts on the same id can't both produce `version=N+1`.
  """

  use CspApi.DataCase, async: false

  alias CspApi.{Fixtures, MongoX, Repo, StandardSets}
  alias CspApi.Schemas.StandardSet

  defp base_attrs(set, overrides) do
    Map.merge(
      %{
        id: set.id,
        title: set.title,
        subject: set.subject,
        educationLevels: set.educationLevels,
        jurisdiction: %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title},
        document: %{"id" => "D1", "title" => "MD Math"},
        standards: %{
          "S1" => %{"id" => "S1", "depth" => 0, "position" => 100, "description" => "v1"}
        }
      },
      overrides
    )
  end

  test "upsert writes the new revision and bumps version monotonically" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    original_version = Repo.get!(StandardSet, set.id).version

    {:ok, _} = StandardSets.upsert(base_attrs(set, %{title: "rev2"}))
    {:ok, _} = StandardSets.upsert(base_attrs(set, %{title: "rev3"}))

    final = Repo.get!(StandardSet, set.id)
    assert final.title == "rev3"
    assert final.version == original_version + 2

    versions = MongoX.find("standard_set_versions", %{"standardSetId" => set.id})
    assert length(versions) == 2, "expected one history row per upsert (got #{length(versions)})"
  end

  test "concurrent upserts can't produce two rows with the same version" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    original_version = Repo.get!(StandardSet, set.id).version

    # Fan out 8 simultaneous upserts on the same id. With the old
    # read-then-write logic, several would race and land on the same
    # version=N+1. With `$inc`, Mongo serializes them and each lands
    # at a distinct version in [N+1, N+8].
    1..8
    |> Task.async_stream(
      fn i ->
        StandardSets.upsert(base_attrs(set, %{title: "rev-#{i}"}))
      end,
      max_concurrency: 8,
      ordered: false,
      timeout: 30_000
    )
    |> Enum.each(fn {:ok, {:ok, _}} -> :ok end)

    versions =
      MongoX.find("standard_set_versions", %{"standardSetId" => set.id})
      |> Enum.map(& &1["version"])

    # Each upsert stashes the PRE-update version. So we expect the
    # written history versions to be [original, original+1, ..., original+7].
    expected = Enum.to_list(original_version..(original_version + 7))
    assert Enum.sort(versions) == expected,
      "history versions weren't strictly increasing: #{inspect(Enum.sort(versions))}"

    final = Repo.get!(StandardSet, set.id)
    assert final.version == original_version + 8
  end

  test "invalid attrs return {:error, changeset}, nothing is written" do
    Fixtures.insert_jurisdiction()

    assert {:error, %Ecto.Changeset{valid?: false}} =
             StandardSets.upsert(%{
               id: "new-set",
               # missing :title and :subject — both `validate_required`
               jurisdiction: %{"id" => "MD", "title" => "Maryland"}
             })

    refute Repo.get(StandardSet, "new-set")
  end
end
