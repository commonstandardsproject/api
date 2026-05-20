# Seeds the minimum dataset the Python contract suite expects:
#   * 51 jurisdictions (50 US states + DC; Maryland with the prod id)
#   * one Maryland standard set with the prod id, a small hierarchy
#   * a smoke-test user with a known apiKey, isCommitter=true
#
# Run with the test-mode DB:
#
#   MONGO_URL_TEST=mongodb://localhost:27017/csp-contract-test \
#   MIX_ENV=test mix run priv/seed_contract.exs
#
# Idempotent — drops the configured database before reseeding.

alias CspApi.Schemas.{Jurisdiction, StandardSet}
alias CspApi.{Repo, Users}

# Reset the DB so re-runs are clean.
{:ok, _} = Application.ensure_all_started(:csp_api)
Mongo.Ecto.command(Repo, dropDatabase: 1)

# Smoke user: isCommitter so the change_status endpoint accepts it.
Users.create(%{
  id: "smoke-user",
  email: "smoke@test.com",
  apiKey: "smoke-key-12345",
  isCommitter: true,
  profile: %{"name" => "Smoke Tester"}
})

# 50 US states + DC. Maryland uses the prod id the contract suite expects.
states = [
  {"AL", "Alabama"}, {"AK", "Alaska"}, {"AZ", "Arizona"}, {"AR", "Arkansas"},
  {"CA", "California"}, {"CO", "Colorado"}, {"CT", "Connecticut"}, {"DE", "Delaware"},
  {"DC", "District of Columbia"}, {"FL", "Florida"}, {"GA", "Georgia"}, {"HI", "Hawaii"},
  {"ID", "Idaho"}, {"IL", "Illinois"}, {"IN", "Indiana"}, {"IA", "Iowa"},
  {"KS", "Kansas"}, {"KY", "Kentucky"}, {"LA", "Louisiana"}, {"ME", "Maine"},
  {"49FCDFBD2CF04033A9C347BFA0584DF0", "Maryland"}, {"MA", "Massachusetts"},
  {"MI", "Michigan"}, {"MN", "Minnesota"}, {"MS", "Mississippi"}, {"MO", "Missouri"},
  {"MT", "Montana"}, {"NE", "Nebraska"}, {"NV", "Nevada"}, {"NH", "New Hampshire"},
  {"NJ", "New Jersey"}, {"NM", "New Mexico"}, {"NY", "New York"}, {"NC", "North Carolina"},
  {"ND", "North Dakota"}, {"OH", "Ohio"}, {"OK", "Oklahoma"}, {"OR", "Oregon"},
  {"PA", "Pennsylvania"}, {"RI", "Rhode Island"}, {"SC", "South Carolina"},
  {"SD", "South Dakota"}, {"TN", "Tennessee"}, {"TX", "Texas"}, {"UT", "Utah"},
  {"VT", "Vermont"}, {"VA", "Virginia"}, {"WA", "Washington"}, {"WV", "West Virginia"},
  {"WI", "Wisconsin"}, {"WY", "Wyoming"}
]

Enum.each(states, fn {id, title} ->
  %Jurisdiction{}
  |> Jurisdiction.changeset(%{id: id, title: title, type: "state", status: "approved"})
  |> Repo.insert!()
end)

# Maryland Math Grade 1 — id, document id, jurisdiction id all match what
# /home/user/api/contract_tests/test_standard_sets.py asserts.
md_id = "49FCDFBD2CF04033A9C347BFA0584DF0"
md_math_g1 = "#{md_id}_D2604890_grade-01"

standards = %{
  # Root domain, depth 0
  "S_ROOT" => %{
    "id" => "S_ROOT",
    "depth" => 0,
    "position" => 100,
    "description" => "Counting and Cardinality"
  },
  # Cluster, depth 1, parent S_ROOT
  "S_CLUSTER" => %{
    "id" => "S_CLUSTER",
    "depth" => 1,
    "position" => 90,
    "description" => "Know number names and the count sequence."
  },
  # Two leaves, depth 2, parent S_CLUSTER
  "S_LEAF_1" => %{
    "id" => "S_LEAF_1",
    "depth" => 2,
    "position" => 80,
    "description" => "Count to 100 by ones and by tens.",
    "statementNotation" => "1.CC.A.1"
  },
  "S_LEAF_2" => %{
    "id" => "S_LEAF_2",
    "depth" => 2,
    "position" => 70,
    "description" => "Count forward beginning from any given number.",
    "statementNotation" => "1.CC.A.2"
  }
}

%StandardSet{}
|> StandardSet.changeset(%{
  id: md_math_g1,
  title: "Grade 1",
  subject: "Mathematics",
  normalizedSubject: "math",
  educationLevels: ["01"],
  jurisdiction: %{"id" => md_id, "title" => "Maryland"},
  cspStatus: %{"value" => "visible"},
  license: %{
    "title" => "CC BY 4.0 US",
    "URL" => "http://creativecommons.org/licenses/by/4.0/us/",
    "rightsHolder" => "Common Curriculum, Inc."
  },
  document: %{
    "id" => "D2604890",
    "title" => "Maryland Mathematics Grade 1",
    "asnIdentifier" => "D2604890",
    "publicationStatus" => "Published"
  },
  standards: standards
})
|> Repo.insert!()

# A second, hidden set for the hideHiddenSets test.
%StandardSet{}
|> StandardSet.changeset(%{
  id: "#{md_id}_HIDDEN",
  title: "Hidden set",
  subject: "Mathematics",
  educationLevels: ["02"],
  jurisdiction: %{"id" => md_id, "title" => "Maryland"},
  cspStatus: %{"value" => "hidden"},
  license: %{
    "title" => "CC BY 4.0 US",
    "URL" => "http://creativecommons.org/licenses/by/4.0/us/",
    "rightsHolder" => "Common Curriculum, Inc."
  },
  document: %{"id" => "D_HIDDEN", "title" => "Hidden doc", "asnIdentifier" => "D_HIDDEN"},
  standards: %{}
})
|> Repo.insert!()

IO.puts("Seeded:")
IO.puts("  - smoke-user (apiKey=smoke-key-12345, isCommitter=true)")
IO.puts("  - 51 jurisdictions including Maryland (id=#{md_id})")
IO.puts("  - standard_set #{md_math_g1}")
IO.puts("  - one hidden standard_set under Maryland")
