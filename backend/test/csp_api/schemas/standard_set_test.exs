defmodule CspApi.Schemas.StandardSetTest do
  use ExUnit.Case, async: true

  alias CspApi.Schemas.StandardSet

  test "requires title and subject" do
    cs = StandardSet.changeset(%StandardSet{}, %{id: "x"})
    refute cs.valid?
    assert Keyword.has_key?(cs.errors, :title)
    assert Keyword.has_key?(cs.errors, :subject)
  end

  test "rejects unknown education levels" do
    cs =
      StandardSet.changeset(%StandardSet{}, %{
        id: "x",
        title: "Grade 1",
        subject: "Math",
        educationLevels: ["01", "ZZ-not-real"]
      })

    refute cs.valid?
    assert Keyword.has_key?(cs.errors, :educationLevels)
  end

  test "accepts the canonical education-level vocabulary" do
    cs =
      StandardSet.changeset(%StandardSet{}, %{
        id: "x",
        title: "Grade 1",
        subject: "Math",
        educationLevels: ["Pre-K", "K", "01", "12", "HigherEducation"]
      })

    assert cs.valid?
  end
end
