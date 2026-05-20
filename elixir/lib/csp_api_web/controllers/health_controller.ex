defmodule CspApiWeb.HealthController do
  @moduledoc """
  Liveness check at `GET /healthz`.

  Returns 200 unconditionally as long as the BEAM is up and the
  endpoint is accepting requests. This intentionally does *not*
  check Mongo — load balancers should keep routing traffic to a
  live app even when its database is degraded, otherwise a Mongo
  outage triggers a cascade where every healthy node is yanked
  out of rotation.

  If you want a separate readiness signal that includes
  dependencies, add a `/readyz` route — but keep this one shallow.
  """

  use CspApiWeb, :controller

  def show(conn, _params) do
    json(conn, %{status: "ok", time: DateTime.utc_now() |> DateTime.to_iso8601()})
  end
end
