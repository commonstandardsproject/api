defmodule CspApiWeb.PullRequestsControllerTest do
  use CspApiWeb.ConnCase, async: false

  alias CspApi.{Fixtures, PullRequests}

  describe "POST /pull_requests" do
    test "creates a blank PR for the current user", %{conn: conn} do
      %{"data" => pr} =
        conn |> post("/api/v1/pull_requests", %{}) |> json_response(200)

      assert pr["submitterId"] == "tester"
      assert pr["submitterEmail"] == "test@test.com"
      assert pr["status"] == "draft"
      assert hd(pr["activities"])["type"] == "created"
    end

    test "creates a forked PR from an existing standard set", %{conn: conn} do
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
      pr = PullRequests.create(user, nil)

      %{"data" => fetched} =
        conn |> get("/api/v1/pull_requests/#{pr["_id"]}") |> json_response(200)

      assert fetched["id"] == pr["_id"]
    end
  end

  describe "GET /pull_requests/user/:user_id" do
    test "returns the user's open PRs", %{conn: conn, user: user} do
      pr = PullRequests.create(user, nil)

      %{"data" => list} =
        conn |> get("/api/v1/pull_requests/user/#{user["_id"]}") |> json_response(200)

      assert Enum.any?(list, fn p -> p["id"] == pr["_id"] end)
    end
  end

  describe "POST /pull_requests/:id/submit" do
    test "marks the PR approval-requested", %{conn: conn, user: user} do
      pr = PullRequests.create(user, nil)

      %{"data" => updated} =
        conn |> post("/api/v1/pull_requests/#{pr["_id"]}/submit") |> json_response(200)

      assert updated["status"] == "approval-requested"
    end
  end

  describe "POST /pull_requests/:id/change_status" do
    test "committers can reject", %{conn: conn, user: user} do
      pr = PullRequests.create(user, nil)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr["_id"]}/change_status", %{"status" => "rejected"})
        |> json_response(200)

      assert updated["status"] == "rejected"
    end

    test "invalid status is silently ignored (matches Ruby behavior)", %{conn: conn, user: user} do
      pr = PullRequests.create(user, nil)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr["_id"]}/change_status", %{"status" => "make-up"})
        |> json_response(200)

      assert updated["status"] == "draft"
    end
  end

  describe "POST /pull_requests/:id/comment" do
    test "appends the comment as a new activity", %{conn: conn, user: user} do
      pr = PullRequests.create(user, nil)

      %{"data" => updated} =
        conn
        |> post("/api/v1/pull_requests/#{pr["_id"]}/comment", %{"comment" => "looks great"})
        |> json_response(200)

      assert Enum.any?(updated["activities"], fn a ->
               a["type"] == "comment" and a["title"] == "looks great"
             end)
    end
  end
end
