defmodule CspApi.Fixtures do
  @moduledoc "Inserters for test fixtures. Uses Ecto changesets so we get the same validation the API does."

  alias CspApi.Repo
  alias CspApi.Schemas.{Jurisdiction, StandardSet}

  def insert_jurisdiction(attrs \\ %{}) do
    base = %{
      id: "MD",
      title: "Maryland",
      type: "state",
      status: "approved"
    }

    %Jurisdiction{}
    |> Jurisdiction.changeset(Map.merge(base, atom_keys(attrs)))
    |> Repo.insert!()
  end

  def insert_standard_set(attrs \\ %{}) do
    base = %{
      id: "MD_D1_grade-01",
      title: "Grade 1",
      subject: "Math",
      educationLevels: ["01"],
      jurisdiction: %{id: "MD", title: "Maryland"},
      document: %{"id" => "D1", "title" => "MD Math", "asnIdentifier" => "D1"},
      license: %{
        title: "CC BY 4.0 US",
        URL: "http://creativecommons.org/licenses/by/4.0/us/",
        rightsHolder: "Common Curriculum, Inc."
      },
      # Children at the highest position, descending toward the root —
      # matching how ASN imports lay out the standards collection.
      standards: %{
        "S1" => %{"id" => "S1", "depth" => 2, "position" => 100, "description" => "Standard 1"},
        "S2" => %{"id" => "S2", "depth" => 2, "position" => 90, "description" => "Standard 2"},
        "CL" => %{"id" => "CL", "depth" => 1, "position" => 80, "description" => "Cluster"},
        "ROOT" => %{"id" => "ROOT", "depth" => 0, "position" => 70, "description" => "Root domain"}
      }
    }

    %StandardSet{}
    |> StandardSet.changeset(Map.merge(base, atom_keys(attrs)))
    |> Repo.insert!()
  end

  defp atom_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      kv -> kv
    end)
  end
end
