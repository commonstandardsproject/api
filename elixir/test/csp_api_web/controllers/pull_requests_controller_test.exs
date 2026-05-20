defmodule CspApiWeb.PullRequestsControllerTest do
  use CspApiWeb.ConnCase, async: false

  alias CspApi.{Fixtures, PullRequests}

  describe "POST /pull_requests" do
    test "creates a blank PR for the current user", %{conn: conn} do
      %{"data" => pr} = conn |> post("/api/v1/pull_requests", %{}) |> json_response(200)

      assert pr["submitterId"] == "tester"
      assert pr["submitterEmail"] == "test@test.com"
      assert pr["status"] == "draft"
      assert hd(pr["activities"])["type"] == "created"
    end

    test "forks an existing standard set", %{conn: conn} do
      Fixtures.insert_jurisdiction()
      Fixtures.insert_standard_set()

      %{"data" => pr} =
        conn
        |> post("/api/v1/pull_requests", %{"standardSetId" => "MD_D1_grade-01"})
        |> json_response(200)

      assert pr["forkedFromStandardSetId"] == "MD_D1_grade-01"
      assert pr["standardSet"]["id"] == "MD_D1_grade-01"
      assert pr["standardSet"]["title"] == "Grade 1"
      assert hd(pr["activities"])["type"] == "forked"
    end
  end

  describe "GET /pull_requests/:id" do
    test "returns the PR", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)
      %{"data" => fetched} = conn |> get("/api/v1/pull_requests/#{pr.id}") |> json_response(200)
      assert fetched["id"] == pr.id
    end
  end

  describe "GET /pull_requests/user/:user_id" do
    test "returns the user's open PRs", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => list} =
        conn |> get("/api/v1/pull_requests/user/#{user.id}") |> json_response(200)

      assert Enum.any?(list, fn p -> p["id"] == pr.id end)
    end
  end

  describe "POST /pull_requests/:id/submit" do
    test "marks the PR approval-requested", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => updated} =
        conn |> post("/api/v1/pull_requests/#{pr.id}/submit") |> json_response(200)

      assert updated["status"] == "approval-requested"
    end
  end

  describe "POST /pull_requests/:id/change_status" do
    test "committers can reject", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr.id}/change_status", %{"status" => "rejected"})
        |> json_response(200)

      assert updated["status"] == "rejected"
    end

    test "an unknown status is silently kept as draft (bug-compatible with Ruby)", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr.id}/change_status", %{"status" => "make-up"})
        |> json_response(200)

      assert updated["status"] == "draft"
    end

    test "committers can revise-and-resubmit", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr.id}/change_status", %{
          "status" => "revise-and-resubmit"
        })
        |> json_response(200)

      assert updated["status"] == "revise-and-resubmit"
    end

    test "approving a PR upserts the embedded standardSet", %{conn: conn, user: user} do
      # Mirror of `spec/controllers/pull_requests.rb:136` "should approve
      # and apply": after change_status("approved"), looking up the
      # standardSet by id should return the title the PR carried.
      Fixtures.insert_jurisdiction()
      Fixtures.insert_standard_set()
      pr = PullRequests.create_blank(user)

      conn
      |> post("/api/v1/pull_requests/#{pr.id}", %{
        "data" => %{
          "standardSet" => %{
            "id" => "MD_D1_grade-01",
            "title" => "MD Math Grade 1 (updated)",
            "subject" => "Math",
            "educationLevels" => ["01"],
            "jurisdiction" => %{"id" => "MD", "title" => "Maryland"}
          }
        }
      })
      |> json_response(200)

      conn
      |> post("/api/v1/pull_requests/#{pr.id}/change_status", %{"status" => "approved"})
      |> json_response(200)

      set = CspApi.StandardSets.get("MD_D1_grade-01")
      assert set.title == "MD Math Grade 1 (updated)"
    end
  end

  describe "POST /pull_requests/:id/comment" do
    test "appends the comment as a new activity", %{conn: conn, user: user} do
      pr = PullRequests.create_blank(user)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr.id}/comment", %{"comment" => "looks great"})
        |> json_response(200)

      assert Enum.any?(updated["activities"], fn a ->
               a["type"] == "comment" and a["title"] == "looks great"
             end)
    end

    test "non-committer can still comment on their own PR", %{conn: conn, user: user} do
      # Mirror of `spec/controllers/pull_requests.rb:179`: the comment
      # endpoint authorizes on `can_edit?(pr, user)`, which returns true
      # for the submitter regardless of `isCommitter`.
      pr = PullRequests.create_blank(user)

      # Demote the user mid-test.
      Mongo.Ecto.command(Repo,
        update: "users",
        updates: [%{"q" => %{"_id" => user.id}, "u" => %{"$set" => %{"isCommitter" => false}}}]
      )

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr.id}/comment", %{"comment" => "thanks for the review"})
        |> json_response(200)

      assert Enum.any?(updated["activities"], fn a ->
               a["type"] == "comment" and a["title"] == "thanks for the review"
             end)
    end
  end
end
