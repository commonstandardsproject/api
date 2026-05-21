defmodule CspApi.EmailTest do
  @moduledoc """
  Pins the email-on-status-change side effect. In Ruby,
  `PullRequest.change_status(id, status, comment, send_notice)` triggers
  `Email.send_email(status, model, comment)` when `send_notice` is true.
  The Elixir port routes that through a pluggable adapter — in tests we
  use `CspApi.Email.TestAdapter` which captures payloads in the process
  dictionary.
  """

  use CspApi.DataCase, async: false

  alias CspApi.Fixtures
  alias CspApi.PullRequests
  alias CspApi.Email.TestAdapter

  setup do
    Application.put_env(:csp_api, :email_adapter, TestAdapter)
    Process.put(:sent_emails, [])

    on_exit(fn ->
      # Restore the suite-wide default set in test_helper.exs — these tests
      # swap to PostmarkAdapter for one case and shouldn't pollute the rest
      # of the suite.
      Application.put_env(:csp_api, :email_adapter, TestAdapter)
    end)

    :ok
  end

  test "approving a PR sends the approval email" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    user = Fixtures.insert_committer()
    {:ok, pr} = Fixtures.insert_pull_request_for(user, %{standardSet: %{"id" => set.id}})

    {:ok, _} = PullRequests.change_status(pr.id, "approved", "great work", true)

    [sent] = TestAdapter.sent_emails()
    assert sent.template == "approved"
    assert sent.template_id == 3_694_223
    assert sent.to =~ user.email
    assert sent.model.comment == %{text: "great work"}
  end

  test "send_notice=false suppresses the email" do
    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    user = Fixtures.insert_committer()
    {:ok, pr} = Fixtures.insert_pull_request_for(user, %{standardSet: %{"id" => set.id}})

    {:ok, _} = PullRequests.change_status(pr.id, "rejected", "no", false)

    assert TestAdapter.sent_emails() == []
  end

  describe "payload static parity with models/email.rb" do
    # The Ruby `Email.send_email` builds this exact template_model hash:
    #
    #   {
    #     name:         pr.submitterName,
    #     URL:          "http://commonstandardsproject.com/edit/pull-requests/" + pr.id,
    #     jurisdiction: pr.standardSet.jurisdiction.title,
    #     subject:      pr.standardSet.subject,
    #     title:        pr.standardSet.title,
    #     comment:      comment
    #   }
    #   template_model[:comment] = {text: comment} if comment
    #
    # Pin every key/value so any drift on either side trips this test.

    setup do
      Fixtures.insert_jurisdiction()
      set = Fixtures.insert_standard_set()
      user = Fixtures.insert_committer()

      {:ok, pr} =
        Fixtures.insert_pull_request_for(user, %{
          standardSet: %{
            "id" => set.id,
            "title" => set.title,
            "subject" => set.subject,
            "jurisdiction" => %{"id" => set.jurisdiction.id, "title" => set.jurisdiction.title}
          }
        })

      {:ok, pr: pr, user: user}
    end

    test "approved + comment payload matches Ruby's template_model verbatim", %{pr: pr} do
      {:ok, _} = PullRequests.change_status(pr.id, "approved", "great work", true)

      [sent] = TestAdapter.sent_emails()

      assert sent.template == "approved"
      assert sent.template_id == 3_694_223
      assert sent.to == "#{pr.submitterName} <#{pr.submitterEmail}>"

      assert sent.model == %{
               name: pr.submitterName,
               URL: "http://commonstandardsproject.com/edit/pull-requests/" <> pr.id,
               jurisdiction: "Maryland",
               subject: "Math",
               title: "Grade 1",
               comment: %{text: "great work"}
             }
    end

    test "nil comment renders as comment: nil (matches Ruby's first-assignment branch)", %{
      pr: pr
    } do
      {:ok, _} = PullRequests.change_status(pr.id, "approved", nil, true)

      [sent] = TestAdapter.sent_emails()
      assert sent.model.comment == nil
    end

    test "non-empty comment renders as %{text: comment} (matches Ruby's overwrite branch)", %{
      pr: pr
    } do
      {:ok, _} = PullRequests.change_status(pr.id, "revise-and-resubmit", "please update", true)

      [sent] = TestAdapter.sent_emails()
      assert sent.template == "revise-and-resubmit"
      assert sent.template_id == 3_694_421
      assert sent.model.comment == %{text: "please update"}
    end

    test "admin comment activity sends `admin-comment-added` template", %{pr: pr, user: user} do
      pr = CspApi.PullRequests.get(pr.id)
      _ = CspApi.PullRequests.add_comment(pr, "review note", user)

      [sent] = TestAdapter.sent_emails()
      assert sent.template == "admin-comment-added"
      assert sent.template_id == 3_694_441
      assert sent.model.comment == %{text: "review note"}
    end
  end

  test "Postmark adapter posts to the right endpoint with the right shape" do
    # Use the Postmark adapter with a stub HTTP client so we can assert on
    # the request without hitting the real Postmark API.
    Application.put_env(:csp_api, :email_adapter, CspApi.Email.PostmarkAdapter)
    Application.put_env(:csp_api, :postmark_token, "stub-token")
    Application.put_env(:csp_api, :postmark_http, CspApi.Email.PostmarkAdapter.StubHTTP)

    Fixtures.insert_jurisdiction()
    set = Fixtures.insert_standard_set()
    user = Fixtures.insert_committer()
    {:ok, pr} = Fixtures.insert_pull_request_for(user, %{standardSet: %{"id" => set.id}})

    Process.put(:postmark_calls, [])
    {:ok, _} = PullRequests.change_status(pr.id, "approved", "nice", true)

    [call] = Process.get(:postmark_calls, [])
    assert call.url == "https://api.postmarkapp.com/email/withTemplate"
    assert call.headers["X-Postmark-Server-Token"] == "stub-token"
    assert call.body["TemplateId"] == 3_694_223
    assert call.body["To"] =~ user.email
  end
end
