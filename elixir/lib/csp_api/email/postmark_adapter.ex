defmodule CspApi.Email.PostmarkAdapter do
  @moduledoc """
  Posts transactional emails to Postmark's templated-email endpoint.
  Port of `models/email.rb`'s `PostmarkClient.deliver_with_template`
  call.

  Config keys (set via `config :csp_api, ...` or
  `config/runtime.exs`):

    * `:postmark_token` — Postmark Server API token
    * `:postmark_from`  — From address (defaults to `POSTMARK_FROM_ADDRESS`)
    * `:postmark_http`  — overridable HTTP client (used by tests)
  """

  @endpoint "https://api.postmarkapp.com/email/withTemplate"

  def deliver(%{template_id: nil} = payload) do
    # Ruby silently no-ops if the template name doesn't have a mapping.
    # Preserve that.
    require Logger
    Logger.warning("[postmark] no template_id for #{payload.template}, skipping")
    :ok
  end

  def deliver(%{template_id: template_id, to: to, model: model}) do
    token = Application.fetch_env!(:csp_api, :postmark_token)
    from = Application.get_env(:csp_api, :postmark_from) || System.get_env("POSTMARK_FROM_ADDRESS")

    body = %{
      "From" => from,
      "To" => to,
      "TemplateId" => template_id,
      "TemplateModel" => model
    }

    http().post(
      url: @endpoint,
      headers: %{
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Postmark-Server-Token" => token
      },
      body: body
    )
  end

  defp http do
    Application.get_env(:csp_api, :postmark_http, __MODULE__.HackneyHTTP)
  end

  defmodule HackneyHTTP do
    @moduledoc false

    def post(url: url, headers: headers, body: body) do
      json = Jason.encode!(body)
      headers_list = Enum.map(headers, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end)

      case :httpc.request(
             :post,
             {String.to_charlist(url), headers_list, ~c"application/json", json},
             [],
             []
           ) do
        {:ok, {{_, status, _}, _h, resp_body}} when status in 200..299 ->
          {:ok, resp_body}

        {:ok, {{_, status, _}, _h, resp_body}} ->
          require Logger
          Logger.error("[postmark] non-2xx (#{status}): #{resp_body}")
          {:error, {status, resp_body}}

        {:error, reason} ->
          require Logger
          Logger.error("[postmark] http error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defmodule StubHTTP do
    @moduledoc """
    Test-only HTTP shim. Records each request on the process dict so
    tests can assert what got sent.
    """
    def post(url: url, headers: headers, body: body) do
      existing = Process.get(:postmark_calls, [])
      Process.put(:postmark_calls, existing ++ [%{url: url, headers: headers, body: body}])
      {:ok, "ok"}
    end
  end
end
