defmodule CspApiWeb.HealthController do
  @moduledoc """
  Liveness + Mongo connectivity check at `GET /healthz`.

  Returns 200 with `{"status": "ok"}` when the app can reach Mongo,
  503 with `{"status": "error", ...}` otherwise. Load balancers and
  uptime checks should hit this — it's outside the api_key pipeline.
  """

  use CspApiWeb, :controller

  alias CspApi.Repo

  def show(conn, _params) do
    case ping_mongo() do
      :ok ->
        json(conn, %{status: "ok", time: DateTime.utc_now() |> DateTime.to_iso8601()})

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", reason: reason})
    end
  end

  defp ping_mongo do
    case Mongo.Ecto.command(Repo, ping: 1) do
      %{"ok" => 1.0} -> :ok
      %{"ok" => 1} -> :ok
      other -> {:error, inspect(other)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  catch
    :exit, reason -> {:error, inspect(reason)}
  end
end
