defmodule CspApi.Algolia.AlgoliaAdapter do
  @moduledoc """
  Production adapter for `CspApi.Algolia`. Wraps the `algolia_ex` client
  to bulk-upsert objects into the configured index.

  Requires `ALGOLIA_APPLICATION_ID` and `ALGOLIA_API_KEY` in the
  environment (or `config :algolia, application_id:, api_key:` in
  config/runtime.exs).
  """

  require Logger

  def index(_index_name, []), do: :ok

  def index(index_name, objects) when is_list(objects) do
    client = Algolia.new()

    case Algolia.save_objects(client, index_name, objects, id_attribute: :objectID) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        # Don't crash the calling request. Log the error and move on —
        # mirrors the Ruby app, which catches Algolia failures via the
        # global `rescue_from :all` in api.rb.
        Logger.error("[algolia] failed to index #{length(objects)} objects into #{index_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
