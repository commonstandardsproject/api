defmodule CspApi.Email do
  @moduledoc """
  Email sending — production hits Postmark. In tests we use a stub that
  records calls in the process dictionary so we can assert against them.

  Routed through `Application.fetch_env!(:csp_api, :email_adapter)` so tests
  can swap the implementation.
  """

  @templates %{
    "approval-requested" => 3_694_442,
    "approved" => 3_694_223,
    "rejected" => 3_694_422,
    "admin-comment-added" => 3_694_441,
    "revise-and-resubmit" => 3_694_421
  }

  def send_email(template, pull_request, comment \\ nil) do
    adapter = Application.get_env(:csp_api, :email_adapter, __MODULE__.LogAdapter)

    template_id = Map.get(@templates, template)

    model = %{
      name: pull_request["submitterName"],
      URL: "http://commonstandardsproject.com/edit/pull-requests/" <> pull_request["_id"],
      jurisdiction: get_in(pull_request, ["standardSet", "jurisdiction", "title"]),
      subject: get_in(pull_request, ["standardSet", "subject"]),
      title: get_in(pull_request, ["standardSet", "title"]),
      comment: comment && %{text: comment}
    }

    adapter.deliver(%{
      template: template,
      template_id: template_id,
      to: "#{pull_request["submitterName"]} <#{pull_request["submitterEmail"]}>",
      model: model
    })
  end

  defmodule LogAdapter do
    @moduledoc false
    require Logger

    def deliver(payload) do
      Logger.info("[email] would send #{payload.template} to #{payload.to}")
      :ok
    end
  end

  defmodule TestAdapter do
    @moduledoc false
    def deliver(payload) do
      sent = Process.get(:sent_emails, [])
      Process.put(:sent_emails, [payload | sent])
      :ok
    end

    def sent_emails, do: Process.get(:sent_emails, []) |> Enum.reverse()
  end
end
