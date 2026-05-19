defmodule CspApi.Fixtures do
  @moduledoc "Helpers for inserting minimal test documents."

  alias CspApi.Mongo

  def insert_jurisdiction(attrs \\ %{}) do
    base = %{
      "_id" => "MD",
      "title" => "Maryland",
      "type" => "state",
      "status" => "approved"
    }

    doc = Map.merge(base, attrs)
    Mongo.insert_one("jurisdictions", doc)
    doc
  end

  def insert_standard_set(attrs \\ %{}) do
    base = %{
      "_id" => "MD_D1_grade-01",
      "title" => "Grade 1",
      "subject" => "Math",
      "educationLevels" => ["01"],
      "jurisdiction" => %{"id" => "MD", "title" => "Maryland"},
      "document" => %{"id" => "D1", "title" => "MD Math", "asnIdentifier" => "D1"},
      "license" => %{
        "title" => "CC BY 4.0 US",
        "URL" => "http://creativecommons.org/licenses/by/4.0/us/",
        "rightsHolder" => "Common Curriculum, Inc."
      },
      # Positions descend from child → parent to match how ASN-imported
      # standards are arranged. The hierarchy algorithm walks the
      # position-desc list forward and accumulates ancestors by decreasing
      # depth.
      "standards" => %{
        "S1" => %{"id" => "S1", "depth" => 2, "position" => 100, "description" => "Standard 1"},
        "S2" => %{"id" => "S2", "depth" => 2, "position" => 90, "description" => "Standard 2"},
        "CL" => %{"id" => "CL", "depth" => 1, "position" => 80, "description" => "Cluster"},
        "ROOT" => %{"id" => "ROOT", "depth" => 0, "position" => 70, "description" => "Root domain"}
      }
    }

    doc = Map.merge(base, attrs)
    Mongo.insert_one("standard_sets", doc)
    doc
  end
end
